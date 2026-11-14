'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { StaffUser, Branch } from './types';
import { DEMO_STAFF_USERS, DEMO_BRANCHES } from './mock-data';

interface AuthContextType {
  user: StaffUser | null;
  activeBranch: Branch | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (email: string, password?: string) => Promise<boolean>;
  logout: () => void;
  setActiveBranch: (branch: Branch) => void;
  availableBranches: Branch[];
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<StaffUser | null>(DEMO_STAFF_USERS[0]); // Default to Branch Manager for fast demo
  const [token, setToken] = useState<string | null>('demo-jwt-token');
  const [activeBranch, setActiveBranch] = useState<Branch | null>(DEMO_BRANCHES[0]);

  useEffect(() => {
    // Check localStorage on mount if in browser
    if (typeof window !== 'undefined') {
      const savedUser = localStorage.getItem('motosaas_staff_user');
      const savedBranch = localStorage.getItem('motosaas_active_branch');
      const savedToken = localStorage.getItem('motosaas_staff_token');
      if (savedUser) {
        try {
          setUser(JSON.parse(savedUser));
        } catch {
          // fallback
        }
      }
      if (savedBranch) {
        try {
          setActiveBranch(JSON.parse(savedBranch));
        } catch {
          // fallback
        }
      }
      if (savedToken) setToken(savedToken);
    }
  }, []);

  const login = async (email: string, _password?: string): Promise<boolean> => {
    // Check demo users first
    const matched = DEMO_STAFF_USERS.find(
      (u) => u.email.toLowerCase() === email.toLowerCase() || u.name.toLowerCase().includes(email.toLowerCase())
    );

    if (matched) {
      setUser(matched);
      setToken('demo-jwt-token-' + matched.id);
      const branch = DEMO_BRANCHES.find((b) => b.id === matched.branchId) || DEMO_BRANCHES[0];
      setActiveBranch(branch);
      if (typeof window !== 'undefined') {
        localStorage.setItem('motosaas_staff_user', JSON.stringify(matched));
        localStorage.setItem('motosaas_active_branch', JSON.stringify(branch));
        localStorage.setItem('motosaas_staff_token', 'demo-jwt-token-' + matched.id);
      }
      return true;
    }

    // Default fallback to first demo user
    const fallback = DEMO_STAFF_USERS[0];
    setUser(fallback);
    return true;
  };

  const logout = () => {
    setUser(null);
    setToken(null);
    if (typeof window !== 'undefined') {
      localStorage.removeItem('motosaas_staff_user');
      localStorage.removeItem('motosaas_active_branch');
      localStorage.removeItem('motosaas_staff_token');
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        activeBranch,
        token,
        isAuthenticated: !!user,
        login,
        logout,
        setActiveBranch: (b) => {
          setActiveBranch(b);
          if (typeof window !== 'undefined') {
            localStorage.setItem('motosaas_active_branch', JSON.stringify(b));
          }
        },
        availableBranches: DEMO_BRANCHES,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

