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

/**
 * CPF (Cadastro de Pessoas Físicas) Validator
 * Brazilian tax ID validation with check digit verification
 */

/**
 * Formats a CPF string to XXX.XXX.XXX-XX format
 */
export const formatCPF = (value: string): string => {
  // Remove all non-digit characters
  const digits = value.replace(/\D/g, '');

  // Limit to 11 digits
  const limited = digits.slice(0, 11);

  // Apply formatting
  if (limited.length <= 3) {
    return limited;
  } else if (limited.length <= 6) {
    return `${limited.slice(0, 3)}.${limited.slice(3)}`;
  } else if (limited.length <= 9) {
    return `${limited.slice(0, 3)}.${limited.slice(3, 6)}.${limited.slice(6)}`;
  } else {
    return `${limited.slice(0, 3)}.${limited.slice(3, 6)}.${limited.slice(6, 9)}-${limited.slice(9)}`;
  }
};

/**
 * Validates CPF check digits
 */
export const validateCPF = (cpf: string): boolean => {
  // Remove formatting
  const digits = cpf.replace(/\D/g, '');

  // Must have exactly 11 digits
  if (digits.length !== 11) {
    return false;
  }

  // Check for known invalid CPFs (all same digits)
  if (/^(\d)\1{10}$/.test(digits)) {
    return false;
  }

  // Validate first check digit
  let sum = 0;
  for (let i = 0; i < 9; i++) {
    sum += parseInt(digits.charAt(i)) * (10 - i);
  }
  let remainder = sum % 11;
  const firstCheckDigit = remainder < 2 ? 0 : 11 - remainder;

  if (parseInt(digits.charAt(9)) !== firstCheckDigit) {
    return false;
  }

  // Validate second check digit
  sum = 0;
  for (let i = 0; i < 10; i++) {
    sum += parseInt(digits.charAt(i)) * (11 - i);
  }
  remainder = sum % 11;
  const secondCheckDigit = remainder < 2 ? 0 : 11 - remainder;

  if (parseInt(digits.charAt(10)) !== secondCheckDigit) {
    return false;
  }

  return true;
};

/**
 * Gets just the digits from a CPF string (removes formatting)
 */
export const getDigitsOnly = (cpf: string): string => {
  return cpf.replace(/\D/g, '');
};
