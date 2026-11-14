'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { OrgAdminUser } from './types';
import { CURRENT_ORG_ADMIN } from './mock-data';

interface AuthContextType {
  admin: OrgAdminUser;
  token: string | null;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [admin] = useState<OrgAdminUser>(CURRENT_ORG_ADMIN);
  const [token] = useState<string | null>('demo-org-admin-token');

  return (
    <AuthContext.Provider
      value={{
        admin,
        token,
        logout: () => {
          if (typeof window !== 'undefined') {
            window.location.href = '/';
          }
        },
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useOrgAdmin() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useOrgAdmin must be used within an AuthProvider');
  }
  return context;
}

