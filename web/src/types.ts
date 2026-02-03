
export interface FAQItem {
  question: string;
  answer: string;
}

export interface Step {
  id: number;
  title: string;
  description: string;
  colorClass: string;
}

export type CurrencySymbol = 'BRL1' | 'USDC' | 'ETH' | 'POL';

export interface WalletBalance {
  symbol: CurrencySymbol;
  name: string;
  balance: string;
  color: string;
  icon: string;
}

export interface Transaction {
  id: number;
  name: string;
  amount: string;
  date: string;
  icon: string;
  currency: CurrencySymbol;
  type: 'incoming' | 'outgoing';
}
