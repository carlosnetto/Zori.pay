// Copyright (c) 2026 Matera Systems, Inc. All rights reserved.
//
// This source code is the proprietary property of Matera Systems, Inc.
// and is protected by copyright law and international treaties.
//
// This software is NOT open source. Use, reproduction, or distribution
// of this code is strictly governed by the Matera Source License (MSL) v1.0.
//
// A copy of the MSL v1.0 should have been provided with this file.
// If not, please contact: licensing@matera.com

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
