import axios from 'axios';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8080/v1';

const api = axios.create({
  baseURL: API_BASE,
  headers: {
    'Content-Type': 'application/json',
  },
});

export interface User {
  person_id: string;
  email: string;
  display_name: string;
  avatar_url?: string;
}

export interface GoogleCallbackResponse {
  intermediate_token: string;
  expires_in: number;
  user: User;
}

export interface AuthTokens {
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
}

class AuthService {
  private intermediateToken: string | null = null;

  async initiateGoogleLogin(): Promise<string> {
    const redirectUri = import.meta.env.VITE_OAUTH_REDIRECT_URI ||
      'http://localhost:8080/auth/callback';

    const response = await api.post('/auth/google', {
      redirect_uri: redirectUri,
    });

    return response.data.authorization_url;
  }

  async handleGoogleCallback(code: string): Promise<GoogleCallbackResponse> {
    const redirectUri = import.meta.env.VITE_OAUTH_REDIRECT_URI ||
      'http://localhost:8080/auth/callback';

    const response = await api.post<GoogleCallbackResponse>('/auth/google/callback', {
      code,
      redirect_uri: redirectUri,
    });

    this.intermediateToken = response.data.intermediate_token;

    // Store user info
    localStorage.setItem('user', JSON.stringify(response.data.user));

    return response.data;
  }

  async requestPasskeyChallenge() {
    if (!this.intermediateToken) {
      throw new Error('No intermediate token available');
    }

    const response = await api.post('/auth/passkey/challenge', null, {
      headers: {
        Authorization: `Bearer ${this.intermediateToken}`,
      },
    });

    return response.data;
  }

  async verifyPasskey(credential: any): Promise<AuthTokens> {
    if (!this.intermediateToken) {
      throw new Error('No intermediate token available');
    }

    const response = await api.post<AuthTokens>('/auth/passkey/verify', credential, {
      headers: {
        Authorization: `Bearer ${this.intermediateToken}`,
      },
    });

    // Store tokens
    localStorage.setItem('access_token', response.data.access_token);
    localStorage.setItem('refresh_token', response.data.refresh_token);

    this.intermediateToken = null;
    return response.data;
  }

  /**
   * DEVELOPMENT ONLY: Bypass passkey verification and get tokens directly
   * This exchanges the intermediate token for access/refresh tokens without passkey verification
   */
  async verifyPasskeyBypass(): Promise<AuthTokens> {
    if (!this.intermediateToken) {
      throw new Error('No intermediate token available');
    }

    const response = await api.post<AuthTokens>('/auth/dev/bypass-passkey', {}, {
      headers: {
        Authorization: `Bearer ${this.intermediateToken}`,
      },
    });

    // Store tokens
    localStorage.setItem('access_token', response.data.access_token);
    localStorage.setItem('refresh_token', response.data.refresh_token);

    this.intermediateToken = null;
    return response.data;
  }

  async refreshToken(): Promise<AuthTokens> {
    const refreshToken = localStorage.getItem('refresh_token');
    if (!refreshToken) {
      throw new Error('No refresh token available');
    }

    const response = await api.post<AuthTokens>('/auth/refresh', {
      refresh_token: refreshToken,
    });

    localStorage.setItem('access_token', response.data.access_token);
    localStorage.setItem('refresh_token', response.data.refresh_token);

    return response.data;
  }

  async logout(): Promise<void> {
    const accessToken = localStorage.getItem('access_token');

    if (accessToken) {
      try {
        await api.post('/auth/logout', null, {
          headers: {
            Authorization: `Bearer ${accessToken}`,
          },
        });
      } catch (error) {
        console.error('Logout error:', error);
      }
    }

    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    localStorage.removeItem('user');
  }

  getAccessToken(): string | null {
    return localStorage.getItem('access_token');
  }

  getUser(): User | null {
    const userStr = localStorage.getItem('user');
    if (!userStr) return null;
    try {
      return JSON.parse(userStr);
    } catch {
      return null;
    }
  }

  isAuthenticated(): boolean {
    return !!this.getAccessToken();
  }
}

export const authService = new AuthService();
