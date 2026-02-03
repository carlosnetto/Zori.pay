
import React from 'react';
import { FAQItem, Step } from './types';

export const FAQ_DATA: FAQItem[] = [
  {
    question: "What is Zori?",
    answer: "Zori is a travel payment app that lets you pay like a local in any country using digital currencies and local QR payment systems or compatible smartglasses."
  },
  {
    question: "Is Zori a crypto wallet?",
    answer: "No. Zori is designed for everyday people, not crypto users. Behind the scenes, stablecoins make payments fast and inexpensive, but for you it feels like using normal money."
  },
  {
    question: "What are 'Digital Dollars' and 'Digital Euros'?",
    answer: "They are digital versions of currencies powered by stablecoins. They are not bank deposits or government-issued money, but they are designed to maintain a 1:1 value with their respective currencies."
  },
  {
    question: "How do I pay with Zori?",
    answer: "Open the app, scan the local QR code, and confirm. Zori detects the currency and pays in local money automatically. You can also use compatible smartglasses for a hands-free experience."
  },
  {
    question: "What QR codes does Zori support?",
    answer: "Zori works with local payment systems such as Pix (Brazil), UPI (India), and other global QR networks."
  },
  {
    question: "Do I pay foreign transaction fees?",
    answer: "No traditional foreign transaction fees like cards charge. When you convert between digital currencies, a small FX fee is included in the rate. This spread is significantly lower than what banks typically charge."
  },
  {
    question: "How does Zori make money?",
    answer: "Zori includes a small margin in the currency conversion rate when you switch between digital currencies. This is transparent in the rate shown to you before you confirm."
  },
  {
    question: "Do merchants need Zori?",
    answer: "No. Merchants receive normal local currency through their existing systems. They don't even know you used Zori."
  },
  {
    question: "Is my money safe?",
    answer: "Zori uses secure infrastructure and regulated digital currency providers to protect your funds and transactions."
  }
];

export const STEPS: Step[] = [
  {
    id: 1,
    title: "Hold digital currencies",
    description: "Keep balances in Digital Dollars, Digital Euros, Digital Reais and more. Powered by stablecoins to keep a 1:1 value.",
    colorClass: "bg-blue-100 text-blue-600"
  },
  {
    id: 2,
    title: "Convert instantly",
    description: "Switch between currencies in seconds at near-FX rates. You always see the rate before confirming.",
    colorClass: "bg-purple-100 text-purple-600"
  },
  {
    id: 3,
    title: "Scan and pay",
    description: "Zori recognizes the QR code and pays in the local currency automatically via phone or smartglasses.",
    colorClass: "bg-green-100 text-green-600"
  }
];
