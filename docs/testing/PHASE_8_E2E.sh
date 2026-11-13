#!/usr/bin/env bash
#
# Phase 8 Customer App end-to-end API verification.
#
# Prerequisites:
#   - PostgreSQL container "motosaas_postgres" running
#   - Seed applied: docs/demo-data/PHASE_8_DEMO_SEED.sql
#   - API running at http://localhost:5053
#   - curl, jq, python3, docker
#
# Usage:
#   ./docs/testing/PHASE_8_E2E.sh
#
set -u

BASE=${BASE:-http://localhost:5053/api/v1}
OUT=${OUT:-$(mktemp -d)/phase8-e2e}
TENANT='11111111-1111-1111-1111-111111111111'
BRANCH='22222222-2222-2222-2222-222222222222'
MODEL='44444444-4444-4444-4444-444444444444'
VARIANT='55555555-5555-5555-5555-555555555555'
COLOR='66666666-6666-6666-6666-666666666666'
VEHICLE='99999999-9999-9999-9999-999999999999'
BOOKING='cccccccc-cccc-cccc-cccc-cccccccccccc'
JOBCARD='dddddddd-dddd-dddd-dddd-dddddddddddd'
DB_CONTAINER=${DB_CONTAINER:-motosaas_postgres}

mkdir -p "$OUT"
FAILURES=0

future_date() {
  # $1 = days from today, $2 = hour (UTC)
  python3 - "$1" "$2" <<'PY'
import datetime as dt, sys
days, hour = int(sys.argv[1]), int(sys.argv[2])
d = dt.datetime.now(dt.timezone.utc) + dt.timedelta(days=days)
print(d.replace(hour=hour, minute=0, second=0, microsecond=0).strftime('%Y-%m-%dT%H:%M:%SZ'))
PY
}

# Reset the seeded estimate so the approval flow can be exercised repeatedly.
docker exec -i "$DB_CONTAINER" psql -U postgres -d motosaas_db -q \
  -c "UPDATE \"JobCards\" SET \"Status\"=1, \"CustomerApproved\"=false WHERE \"Id\"='$JOBCARD';" \
  -c "UPDATE \"JobCardItems\" SET \"IsApproved\"=false WHERE \"JobCardId\"='$JOBCARD';" \
  >/dev/null 2>&1 || true

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

GUEST=(-H 'X-Dealer-Code: ALAGENDRA')

call branding 200 "${GUEST[@]}" "$BASE/branding/current"
call catalog 200 "${GUEST[@]}" "$BASE/catalog/models"
call model 200 "${GUEST[@]}" "$BASE/catalog/models/$MODEL"
call pricing 200 "${GUEST[@]}" "$BASE/catalog/variants/$VARIANT/pricing?branchId=$BRANCH"
call showroom 200 "${GUEST[@]}" "$BASE/showroom/variants/$VARIANT?colorId=$COLOR"

call enquiry_guest 201 -X POST -H 'Content-Type: application/json' "${GUEST[@]}" \
  -d "{\"branchId\":\"$BRANCH\",\"variantId\":\"$VARIANT\",\"colorId\":\"$COLOR\",\"notes\":\"Guest enquiry from Phase 8 E2E\",\"firstName\":\"Guest\",\"lastName\":\"Rider\",\"phone\":\"9123456780\",\"email\":\"guest@example.com\"}" \
  "$BASE/sales/enquiries"

call testride_guest 201 -X POST -H 'Content-Type: application/json' "${GUEST[@]}" \
  -d "{\"branchId\":\"$BRANCH\",\"variantId\":\"$VARIANT\",\"scheduledAt\":\"$(future_date 3 10)\",\"drivingLicenseNumber\":\"KA0120200000001\",\"firstName\":\"Guest\",\"lastName\":\"Rider\",\"phone\":\"9123456781\"}" \
  "$BASE/sales/test-rides"

call otp_request 200 -X POST -H 'Content-Type: application/json' \
  -d '{"phone":"9876543210","dealerCode":"ALAGENDRA"}' "$BASE/auth/customer/request-otp"

call otp_verify 200 -X POST -H 'Content-Type: application/json' \
  -d '{"phone":"9876543210","otp":"123456","dealerCode":"ALAGENDRA"}' "$BASE/auth/customer/verify-otp"

TOKEN=$(jq -r '.data.accessToken // empty' "$OUT/otp_verify.json")
if [ -z "$TOKEN" ]; then
  echo "FAIL  no access token returned by otp_verify"
  exit 1
fi
AUTH=(-H "Authorization: Bearer $TOKEN")

call profile_get 200 "${AUTH[@]}" "$BASE/customers/me"
call profile_put 200 -X PUT -H 'Content-Type: application/json' "${AUTH[@]}" \
  -d '{"firstName":"Asha","lastName":"Rao","email":"asha.rao@example.com","addressLine1":"42, 12th Main, Indiranagar","city":"Bengaluru","state":"Karnataka","postalCode":"560038"}' \
  "$BASE/customers/me"

call enquiry_customer 201 -X POST -H 'Content-Type: application/json' "${AUTH[@]}" \
  -d "{\"branchId\":\"$BRANCH\",\"variantId\":\"$VARIANT\",\"colorId\":\"$COLOR\",\"notes\":\"Signed-in enquiry from Phase 8 E2E\"}" \
  "$BASE/sales/enquiries"

call testride_customer 201 -X POST -H 'Content-Type: application/json' "${AUTH[@]}" \
  -d "{\"branchId\":\"$BRANCH\",\"variantId\":\"$VARIANT\",\"scheduledAt\":\"$(future_date 4 11)\",\"drivingLicenseNumber\":\"KA0120200000001\"}" \
  "$BASE/sales/test-rides"

call enquiries_mine 200 "${AUTH[@]}" "$BASE/sales/enquiries/mine"
call testrides_mine 200 "${AUTH[@]}" "$BASE/sales/test-rides/mine"
call vehicles 200 "${AUTH[@]}" "$BASE/service/my-vehicles"
call bookings_mine 200 "${AUTH[@]}" "$BASE/service/bookings/mine"

call booking_new 201 -X POST -H 'Content-Type: application/json' "${AUTH[@]}" \
  -d "{\"customerVehicleId\":\"$VEHICLE\",\"branchId\":\"$BRANCH\",\"serviceType\":\"PERIODIC\",\"scheduledDate\":\"$(future_date 2 0)\",\"timeSlot\":\"09:00 - 10:00\",\"customerComplaints\":\"Phase 8 E2E booking\"}" \
  "$BASE/service/bookings"

call tracking_before 200 "${AUTH[@]}" "$BASE/service/bookings/$BOOKING/tracking"
call approve 200 -X PUT -H 'Content-Type: application/json' "${AUTH[@]}" "$BASE/service/job-cards/$JOBCARD/approve"
call tracking_after 200 "${AUTH[@]}" "$BASE/service/bookings/$BOOKING/tracking"

if [ "$FAILURES" -ne 0 ]; then
  echo
  echo "$FAILURES step(s) failed. Responses are in $OUT"
  exit 1
fi

echo
echo "All Phase 8 E2E steps passed. Responses are in $OUT"

# Leave the demo in the "awaiting approval" state so the flow can be shown again.
docker exec -i "$DB_CONTAINER" psql -U postgres -d motosaas_db -q \
  -c "UPDATE \"JobCards\" SET \"Status\"=1, \"CustomerApproved\"=false WHERE \"Id\"='$JOBCARD';" \
  -c "UPDATE \"JobCardItems\" SET \"IsApproved\"=false WHERE \"JobCardId\"='$JOBCARD';" \
  >/dev/null 2>&1 || true
