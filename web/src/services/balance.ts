import axios from 'axios';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8080/v1';

export interface CurrencyBalance {
  currency_code: string;
  balance: string;
  decimals: number;
  formatted_balance: string;
}

export interface BalanceResponse {
  address: string;
  blockchain: string;
  balances: CurrencyBalance[];
}

class BalanceService {
  /**
   * Fetch blockchain balances for the authenticated user
   */
  async getBalances(): Promise<BalanceResponse> {
    const accessToken = localStorage.getItem('access_token');

    if (!accessToken) {
      throw new Error('No access token found. Please log in.');
    }

    try {
      const response = await axios.get<BalanceResponse>(`${API_BASE}/balance`, {
        headers: {
          'Authorization': `Bearer ${accessToken}`
        }
      });

      return response.data;
    } catch (error: any) {
      if (error.response?.status === 401) {
        // Token expired or invalid
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        localStorage.removeItem('user');
        throw new Error('Session expired. Please log in again.');
      }
      throw error;
    }
  }
}

export const balanceService = new BalanceService();
