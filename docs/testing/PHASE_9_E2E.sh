#!/usr/bin/env bash
#
# Phase 9 Sales & CRM end-to-end API verification.
#
# Prerequisites:
#   - PostgreSQL container "motosaas_postgres" running
#   - Seeds applied: docs/demo-data/PHASE_8_DEMO_SEED.sql and PHASE_9_DEMO_SEED.sql
#   - API running at http://localhost:5053
#   - curl, jq, python3, docker
#
# Usage:
#   ./docs/testing/PHASE_9_E2E.sh
#
set -u

BASE=${BASE:-http://localhost:5053/api/v1}
OUT=${OUT:-$(mktemp -d)/phase9-e2e}
BRANCH='22222222-2222-2222-2222-222222222222'
VARIANT='55555555-5555-5555-5555-555555555555'
COLOR='66666666-6666-6666-6666-666666666666'
DB_CONTAINER=${DB_CONTAINER:-motosaas_postgres}
LEAD_PHONE='+919700000002'
TESTRIDE_PHONE='+919700000003'
CANCEL_PHONE='+919700000004'

mkdir -p "$OUT"
FAILURES=0

future_date() {
  python3 - "$1" "$2" <<'PY'
import datetime as dt, sys
days, hour = int(sys.argv[1]), int(sys.argv[2])
d = dt.datetime.now(dt.timezone.utc) + dt.timedelta(days=days)
print(d.replace(hour=hour, minute=0, second=0, microsecond=0).strftime('%Y-%m-%dT%H:%M:%SZ'))
PY
}

cleanup() {
  docker exec -i "$DB_CONTAINER" psql -U postgres -d motosaas_db -q \
    -c "DELETE FROM \"Quotations\" WHERE \"CustomerId\" IN (SELECT \"Id\" FROM \"Customers\" WHERE \"Phone\" IN ('$LEAD_PHONE','$TESTRIDE_PHONE','$CANCEL_PHONE'));" \
    -c "DELETE FROM \"TestRides\" WHERE \"CustomerId\" IN (SELECT \"Id\" FROM \"Customers\" WHERE \"Phone\" IN ('$LEAD_PHONE','$TESTRIDE_PHONE','$CANCEL_PHONE'));" \
    -c "DELETE FROM \"EnquiryFollowUps\" WHERE \"EnquiryId\" IN (SELECT \"Id\" FROM \"Enquiries\" WHERE \"CustomerId\" IN (SELECT \"Id\" FROM \"Customers\" WHERE \"Phone\" IN ('$LEAD_PHONE','$TESTRIDE_PHONE','$CANCEL_PHONE')));" \
    -c "DELETE FROM \"Enquiries\" WHERE \"CustomerId\" IN (SELECT \"Id\" FROM \"Customers\" WHERE \"Phone\" IN ('$LEAD_PHONE','$TESTRIDE_PHONE','$CANCEL_PHONE'));" \
    -c "DELETE FROM \"Customers\" WHERE \"Phone\" IN ('$LEAD_PHONE','$TESTRIDE_PHONE','$CANCEL_PHONE');" \
    >/dev/null 2>&1 || true
}

cleanup

call() {
  local name=$1 expected=$2; shift 2
  local file="$OUT/$name.json" code
  code=$(curl -s -o "$file" -w '%{http_code}' "$@")
  echo "$code" > "$OUT/$name.status"
  if [ "$code" = "$expected" ]; then
    echo "PASS  $name -> HTTP $code"
  else
    echo "FAIL  $name -> HTTP $code (expected $expected)"
    FAILURES=$((FAILURES + 1))
  fi
}

assert_json() {
  local name=$1 filter=$2 expected=$3 actual
  actual=$(jq -r "$filter" "$OUT/$name.json" 2>/dev/null)
  if [ "$actual" = "$expected" ]; then
    echo "PASS  $name assertion: $filter == $expected"
  else
    echo "FAIL  $name assertion: $filter == '$actual' (expected '$expected')"
    FAILURES=$((FAILURES + 1))
  fi
}

assert_nonempty() {
  local name=$1 filter=$2 actual
  actual=$(jq -r "$filter" "$OUT/$name.json" 2>/dev/null)
  if [ -n "$actual" ] && [ "$actual" != "null" ]; then
    echo "PASS  $name assertion: $filter present"
  else
    echo "FAIL  $name assertion: $filter is empty"
    FAILURES=$((FAILURES + 1))
  fi
}

assert_json_number() {
  local name=$1 filter=$2 expected=$3 actual
  actual=$(jq -r "$filter" "$OUT/$name.json" 2>/dev/null)
  if python3 -c 'import sys; sys.exit(0 if float(sys.argv[1]) == float(sys.argv[2]) else 1)' "$actual" "$expected" 2>/dev/null; then
    echo "PASS  $name assertion: $filter == $expected"
  else
    echo "FAIL  $name assertion: $filter == '$actual' (expected '$expected')"
    FAILURES=$((FAILURES + 1))
  fi
}

# 1. Authentication ---------------------------------------------------------
call login_manager 200 -X POST -H 'Content-Type: application/json' \
  -d '{"usernameOrEmail":"manager.priya","password":"Demo@123","dealerCode":"ALAGENDRA"}' \
  "$BASE/auth/staff/login"
assert_json login_manager '.data.user.userType' 'DEALER_STAFF'
assert_json login_manager '.data.user.roles | sort | join(",")' 'BranchManager,SalesManager'
MANAGER_TOKEN=$(jq -r '.data.accessToken // empty' "$OUT/login_manager.json")
MANAGER_AUTH=(-H "Authorization: Bearer $MANAGER_TOKEN")

call login_executive 200 -X POST -H 'Content-Type: application/json' \
  -d '{"usernameOrEmail":"advisor.kiran","password":"Demo@123","dealerCode":"ALAGENDRA"}' \
  "$BASE/auth/staff/login"
assert_json login_executive '.data.user.roles | index("SalesExecutive") != null' 'true'

call dashboard_unauthorized 401 "$BASE/staff/sales/dashboard"

# 2. Pipeline and dashboard -------------------------------------------------
call dashboard 200 "${MANAGER_AUTH[@]}" "$BASE/staff/sales/dashboard"
assert_json dashboard '.success' 'true'
assert_nonempty dashboard '.data.generatedAt'

call pipeline 200 "${MANAGER_AUTH[@]}" "$BASE/staff/sales/leads?page=1&pageSize=10&status=NEW,CONTACTED"
assert_json pipeline '.success' 'true'
assert_nonempty pipeline '.data.totalCount'

call executives 200 "${MANAGER_AUTH[@]}" "$BASE/staff/sales/sales-executives"
assert_json executives '.success' 'true'
EXECUTIVE_ID=$(jq -r '.data[] | select(.roles | index("SalesExecutive")) | .id' "$OUT/executives.json" | head -1)
if [ -z "$EXECUTIVE_ID" ]; then
  echo "FAIL  no sales executive available for assignment"
  FAILURES=$((FAILURES + 1))
fi

# 3. Lead capture, auto-assignment and follow-up ----------------------------
call capture_lead 201 -X POST -H 'Content-Type: application/json' "${MANAGER_AUTH[@]}" \
  -d "{\"firstName\":\"Phase9\",\"lastName\":\"Buyer\",\"phone\":\"9700000002\",\"email\":\"phase9.buyer@example.com\",\"city\":\"Bengaluru\",\"branchId\":null,\"variantId\":\"$VARIANT\",\"colorId\":\"$COLOR\",\"source\":\"WalkIn\",\"notes\":\"Phase 9 E2E lead\",\"expectedPurchaseDate\":\"$(future_date 15 0)\"}" \
  "$BASE/staff/sales/leads"
assert_json capture_lead '.data.status' 'NEW'
assert_json capture_lead '.data.branchId' "$BRANCH"
assert_nonempty capture_lead '.data.assignedSalesExecutiveId'
LEAD_ID=$(jq -r '.data.id // empty' "$OUT/capture_lead.json")

call get_lead 200 "${MANAGER_AUTH[@]}" "$BASE/staff/sales/leads/$LEAD_ID"
assert_json get_lead '.data.phone' "$LEAD_PHONE"

call assign_lead 200 -X PUT -H 'Content-Type: application/json' "${MANAGER_AUTH[@]}" \
  -d "{\"salesExecutiveId\":\"$EXECUTIVE_ID\"}" "$BASE/staff/sales/leads/$LEAD_ID/assign"
assert_json assign_lead ".data.assignedSalesExecutiveId" "$EXECUTIVE_ID"

call status_contacted 200 -X PUT -H 'Content-Type: application/json' "${MANAGER_AUTH[@]}" \
  -d '{"status":"Contacted"}' "$BASE/staff/sales/leads/$LEAD_ID/status"
assert_json status_contacted '.data.status' 'CONTACTED'

call follow_up 201 -X POST -H 'Content-Type: application/json' "${MANAGER_AUTH[@]}" \
  -d "{\"channel\":\"Phone\",\"outcome\":\"Interested\",\"notes\":\"Phase 9 E2E follow-up\",\"nextFollowUpAt\":\"$(future_date 3 10)\"}" \
  "$BASE/staff/sales/leads/$LEAD_ID/follow-ups"
assert_json follow_up '.data.outcome' 'INTERESTED'

call get_lead_after_follow_up 200 "${MANAGER_AUTH[@]}" "$BASE/staff/sales/leads/$LEAD_ID"
assert_json get_lead_after_follow_up '.data.status' 'CONTACTED'
assert_json get_lead_after_follow_up '.data.followUpCount' '1'

# 4. Dynamic quotation ------------------------------------------------------
call quotation_preview 200 -X POST -H 'Content-Type: application/json' "${MANAGER_AUTH[@]}" \
  -d "{\"enquiryId\":\"$LEAD_ID\",\"accessoriesCharges\":5000,\"discountAmount\":3000,\"validDays\":7}" \
  "$BASE/quotations/preview"
assert_json_number quotation_preview '.data.exShowroomPrice' '182000'
assert_json_number quotation_preview '.data.rtoPercent' '12'
assert_json_number quotation_preview '.data.rtoCharges' '21840'
assert_json_number quotation_preview '.data.insuranceCharges' '6370'
assert_json_number quotation_preview '.data.handlingCharges' '2500'
assert_json_number quotation_preview '.data.totalOnRoadPrice' '214710'

call quotation_create 201 -X POST -H 'Content-Type: application/json' "${MANAGER_AUTH[@]}" \
  -d "{\"enquiryId\":\"$LEAD_ID\",\"accessoriesCharges\":5000,\"discountAmount\":3000,\"validDays\":7,\"notes\":\"Phase 9 E2E quotation\"}" \
  "$BASE/quotations"
assert_json quotation_create '.data.status' 'ACTIVE'
assert_json_number quotation_create '.data.totalOnRoadPrice' '214710'
assert_nonempty quotation_create '.data.quotationNumber'
QUOTATION_ID=$(jq -r '.data.id // empty' "$OUT/quotation_create.json")
QUOTATION_NUMBER=$(jq -r '.data.quotationNumber // empty' "$OUT/quotation_create.json")

call quotation_get 200 "${MANAGER_AUTH[@]}" "$BASE/quotations/$QUOTATION_ID"
assert_json quotation_get '.data.quotationNumber' "$QUOTATION_NUMBER"

call quotation_list 200 "${MANAGER_AUTH[@]}" "$BASE/quotations?page=1&pageSize=10&enquiryId=$LEAD_ID"
assert_json quotation_list '.data.totalCount' '1'

call quotation_expire 200 -X POST "${MANAGER_AUTH[@]}" "$BASE/quotations/$QUOTATION_ID/expire"
assert_json quotation_expire '.data.status' 'EXPIRED'

# 5. Test ride scheduling + completion verification -------------------------
call testride_schedule 201 -X POST -H 'Content-Type: application/json' -H 'X-Dealer-Code: ALAGENDRA' \
  -d "{\"branchId\":\"$BRANCH\",\"variantId\":\"$VARIANT\",\"scheduledAt\":\"$(future_date 2 10)\",\"drivingLicenseNumber\":\"KA0120200000009\",\"firstName\":\"Phase9\",\"lastName\":\"Rider\",\"phone\":\"9700000003\"}" \
  "$BASE/sales/test-rides"
TEST_RIDE_ID=$(jq -r '.data.id // empty' "$OUT/testride_schedule.json")

call testride_queue 200 "${MANAGER_AUTH[@]}" "$BASE/staff/sales/test-rides?status=SCHEDULED"
assert_json testride_queue ".data | map(.id) | index(\"$TEST_RIDE_ID\") != null" 'true'

call testride_complete_rejected 400 -X POST -H 'Content-Type: application/json' "${MANAGER_AUTH[@]}" \
  -d '{"drivingLicenseVerified":false,"feedbackNotes":"Licence not checked"}' \
  "$BASE/staff/sales/test-rides/$TEST_RIDE_ID/complete"

call testride_complete 200 -X POST -H 'Content-Type: application/json' "${MANAGER_AUTH[@]}" \
  -d '{"drivingLicenseVerified":true,"feedbackNotes":"Phase 9 E2E completion; licence verified."}' \
  "$BASE/staff/sales/test-rides/$TEST_RIDE_ID/complete"
assert_json testride_complete '.data.status' 'COMPLETED'
assert_json testride_complete '.data.drivingLicenseNumber' 'KA0120200000009'

# 6. Test ride cancellation -------------------------------------------------
call testride_schedule_cancel 201 -X POST -H 'Content-Type: application/json' -H 'X-Dealer-Code: ALAGENDRA' \
  -d "{\"branchId\":\"$BRANCH\",\"variantId\":\"$VARIANT\",\"scheduledAt\":\"$(future_date 3 11)\",\"drivingLicenseNumber\":\"KA0120200000010\",\"firstName\":\"Phase9\",\"lastName\":\"Cancel\",\"phone\":\"9700000004\"}" \
  "$BASE/sales/test-rides"
CANCEL_RIDE_ID=$(jq -r '.data.id // empty' "$OUT/testride_schedule_cancel.json")

call testride_cancel 200 -X POST -H 'Content-Type: application/json' "${MANAGER_AUTH[@]}" \
  -d '{"reason":"Customer requested a different weekend."}' \
  "$BASE/staff/sales/test-rides/$CANCEL_RIDE_ID/cancel"
assert_json testride_cancel '.data.status' 'CANCELLED'

call dashboard_after 200 "${MANAGER_AUTH[@]}" "$BASE/staff/sales/dashboard"
assert_json dashboard_after '.success' 'true'

# 7. Invalid stage transition ----------------------------------------------
call status_invalid 400 -X PUT -H 'Content-Type: application/json' "${MANAGER_AUTH[@]}" \
  -d '{"status":"New"}' "$BASE/staff/sales/leads/$LEAD_ID/status"

cleanup

if [ "$FAILURES" -ne 0 ]; then
  echo
  echo "$FAILURES step(s) failed. Responses are in $OUT"
  exit 1
fi

echo
echo "All Phase 9 E2E steps passed. Responses are in $OUT"
