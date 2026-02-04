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

// =============================================================================
// BUG FIXES & LESSONS LEARNED (2026-02-04)
// =============================================================================
//
// 1. PENDING CONTACT CHANGES NOT SHOWING IN SUMMARY
//    Problem: New phones/emails added in Contact section were tracked in
//    `pendingContactChanges` state but the "Pending Changes" summary block
//    only displayed `pendingChanges` (field changes like name, DOB, etc.).
//    Fix: Added rendering of pendingContactChanges in the summary block,
//    including new phones, deleted phones, new emails, deleted emails,
//    and login credential changes.
//
// 2. PHONE/EMAIL TYPES NOT MATCHING DATABASE SCHEMA
//    Problem: UI had phone types (mobile, home, work) but database schema
//    in v002_registration.xml defines: mobile, work, voip for phones and
//    personal, work, other for emails.
//    Fix: Updated dropdown options to match database: phones now have
//    mobile, home, work, voip, other; emails have personal, work, other.
//    Added translations for 'voip' and 'other' in all 6 languages.
//
// 3. COULDN'T DELETE LOGIN CREDENTIAL PHONES/EMAILS
//    Problem: The delete button was hidden for phones/emails marked as
//    `is_primary_for_login` with condition `!phone.is_primary_for_login`.
//    Fix: Removed that restriction, allowing deletion of any phone/email.
//    Added validation in saveSection() to require selecting a new login
//    before deleting the current one.
//
// 4. COULDN'T CHANGE LOGIN CREDENTIALS
//    Problem: No UI existed to change which phone/email is used for login.
//    Fix: Added `newLoginPhone` and `newLoginEmail` state. Added key icon
//    button on non-login phones/emails to set them as the new login.
//    Shows "new login" badge in green when selected.
//
// 5. "SET AS LOGIN" NOT SHOWING FOR NEW PHONES/EMAILS
//    Problem: The key icon to set as login only appeared for existing
//    phones/emails from the database, not for newly added ones in the
//    `newPhones`/`newEmails` arrays.
//    Fix: Added the key icon button to the "New phones/emails being added"
//    rendering sections, allowing users to set a new phone/email as login
//    immediately after adding it.
//
// 6. PENDING CHANGES NOT EDITABLE AFTER SAVING
//    Problem: After clicking checkmark to save contact changes (moving them
//    to pendingContactChanges), re-entering edit mode didn't restore the
//    data to editable state. The "set as login" option disappeared.
//    Fix: Updated startEditingSection() to restore pendingContactChanges
//    back into the editable state (newPhones, deletedPhones, newLoginPhone,
//    etc.) when re-entering contact edit mode. Also updated pending display
//    sections to only show when NOT in edit mode.
//
// IMPORTANT PATTERNS TO REMEMBER:
// - Contact changes have TWO states: editable (newPhones, etc.) and pending
//   (pendingContactChanges). When saving, data moves from editable to pending.
//   When re-editing, data should be restored from pending to editable.
// - Login credentials require validation: can't delete current login without
//   first selecting a new one.
// - All UI options (dropdowns, buttons) should be available for BOTH existing
//   items from the database AND newly added items in local state.
// - Phone/email types must match database schema - check migrations first.
// =============================================================================

import React, { useState, useEffect } from 'react';
import { Language, translations } from '../translations';
import { profileService, ProfileResponse } from '../services/profile';
import {
  referenceDataService,
  Country,
  State,
  PhoneType,
  EmailType
} from '../services/referenceData';

interface SettingsProps {
  currentLang: Language;
  onBack: () => void;
}

interface EditedFields {
  [key: string]: {
    originalValue: string | null | undefined;
    newValue: string;
    wasBlank: boolean;
  };
}

// Language to locale mapping for date formatting
const LANGUAGE_LOCALES: Record<Language, string> = {
  en: 'en-US',
  es: 'es-ES',
  pt: 'pt-BR',
  zh: 'zh-CN',
  fr: 'fr-FR',
  it: 'it-IT',
};

// Format date based on language locale
const formatDateForLocale = (dateStr: string | null | undefined, lang: Language): string => {
  if (!dateStr) return '';
  try {
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) return dateStr;
    return date.toLocaleDateString(LANGUAGE_LOCALES[lang], {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
  } catch {
    return dateStr;
  }
};


type EditableSection = 'personal' | 'documents' | 'contact' | 'address' | 'blockchain' | 'accounts' | null;

const Settings: React.FC<SettingsProps> = ({ currentLang, onBack }) => {
  const t = translations[currentLang].settings;
  const [profile, setProfile] = useState<ProfileResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Reference data state
  const [countries, setCountries] = useState<Country[]>([]);
  const [phoneTypes, setPhoneTypes] = useState<PhoneType[]>([]);
  const [emailTypes, setEmailTypes] = useState<EmailType[]>([]);
  const [referenceDataLoading, setReferenceDataLoading] = useState(true);
  const [copied, setCopied] = useState(false);
  const [editingSection, setEditingSection] = useState<EditableSection>(null);
  const [editedFields, setEditedFields] = useState<EditedFields>({});
  const [pendingChanges, setPendingChanges] = useState<EditedFields>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [sectionError, setSectionError] = useState<string | null>(null);
  const [editWarning, setEditWarning] = useState<string | null>(null);

  // Contact editing state
  const [newPhones, setNewPhones] = useState<Array<{phone_number: string; phone_type: string}>>([]);
  const [deletedPhones, setDeletedPhones] = useState<Set<string>>(new Set());
  const [newEmails, setNewEmails] = useState<Array<{email_address: string; email_type: string}>>([]);
  const [deletedEmails, setDeletedEmails] = useState<Set<string>>(new Set());
  const [newPhoneInput, setNewPhoneInput] = useState({ phone_number: '', phone_type: 'mobile' });
  const [newEmailInput, setNewEmailInput] = useState({ email_address: '', email_type: 'personal' });
  const [phoneError, setPhoneError] = useState<string | null>(null);
  const [emailError, setEmailError] = useState<string | null>(null);
  // Login credential changes
  const [newLoginPhone, setNewLoginPhone] = useState<string | null>(null);
  const [newLoginEmail, setNewLoginEmail] = useState<string | null>(null);

  // Pending contact changes (for submit)
  const [pendingContactChanges, setPendingContactChanges] = useState<{
    newPhones: Array<{phone_number: string; phone_type: string}>;
    deletedPhones: string[];
    newEmails: Array<{email_address: string; email_type: string}>;
    deletedEmails: string[];
    newLoginPhone: string | null;
    newLoginEmail: string | null;
  } | null>(null);

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        setLoading(true);
        setError(null);
        const data = await profileService.getProfile();
        setProfile(data);
      } catch (err: any) {
        console.error('Failed to fetch profile:', err);
        setError(err.message || 'Failed to load profile');
      } finally {
        setLoading(false);
      }
    };

    fetchProfile();
  }, []);

  // Fetch reference data on mount
  useEffect(() => {
    const fetchReferenceData = async () => {
      try {
        setReferenceDataLoading(true);
        const data = await referenceDataService.getReferenceData();
        setCountries(data.countries);
        setPhoneTypes(data.phone_types);
        setEmailTypes(data.email_types);
      } catch (err) {
        console.error('Failed to fetch reference data:', err);
        // Non-critical error - use empty arrays as fallback
      } finally {
        setReferenceDataLoading(false);
      }
    };

    fetchReferenceData();
  }, []);

  const copyToClipboard = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  };

  const getSectionName = (section: EditableSection): string => {
    switch (section) {
      case 'personal': return t.personalSection;
      case 'documents': return t.documentsSection;
      case 'contact': return t.contactSection;
      case 'address': return t.addressSection;
      case 'blockchain': return t.blockchainSection;
      case 'accounts': return t.bankAccountsSection;
      default: return '';
    }
  };

  const startEditingSection = (section: EditableSection) => {
    if (editingSection !== null && editingSection !== section) {
      // Already editing another section - show warning modal
      const currentSectionName = getSectionName(editingSection);
      setEditWarning(t.saveOrCancelFirst?.replace('{section}', currentSectionName) || `Please save or cancel "${currentSectionName}" first`);
      return;
    }
    setEditingSection(section);
    setEditedFields({});
    setSectionError(null);
    setEditWarning(null);

    // Restore pending contact changes when re-entering contact edit mode
    if (section === 'contact' && pendingContactChanges) {
      setNewPhones([...pendingContactChanges.newPhones]);
      setDeletedPhones(new Set(pendingContactChanges.deletedPhones));
      setNewEmails([...pendingContactChanges.newEmails]);
      setDeletedEmails(new Set(pendingContactChanges.deletedEmails));
      setNewLoginPhone(pendingContactChanges.newLoginPhone);
      setNewLoginEmail(pendingContactChanges.newLoginEmail);
      // Clear pending so we don't duplicate when saving again
      setPendingContactChanges(null);
    }
  };

  const cancelEditingSection = () => {
    setEditingSection(null);
    setEditedFields({});
    setSectionError(null);
    // Reset contact editing state
    setNewPhones([]);
    setDeletedPhones(new Set());
    setNewEmails([]);
    setDeletedEmails(new Set());
    setNewPhoneInput({ phone_number: '', phone_type: 'mobile' });
    setNewEmailInput({ email_address: '', email_type: 'personal' });
    setPhoneError(null);
    setEmailError(null);
    setNewLoginPhone(null);
    setNewLoginEmail(null);
  };

  // Phone validation - ITU format: +XX or +XXX followed by digits
  const validatePhone = (phone: string): boolean => {
    const ituPattern = /^\+[1-9]\d{0,2}\d{6,14}$/;
    return ituPattern.test(phone.replace(/[\s\-\(\)]/g, ''));
  };

  // Email validation
  const validateEmail = (email: string): boolean => {
    const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailPattern.test(email);
  };

  const addNewPhone = () => {
    const cleanPhone = newPhoneInput.phone_number.replace(/[\s\-\(\)]/g, '');
    if (!cleanPhone) {
      setPhoneError(t.phoneRequired || 'Phone number is required');
      return;
    }
    if (!validatePhone(cleanPhone)) {
      setPhoneError(t.phoneInvalidFormat || 'Invalid format. Use ITU format: +55...');
      return;
    }
    // Check for duplicates
    const existingPhones = profile?.contact?.phones || [];
    if (existingPhones.some(p => p.phone_number === cleanPhone) || newPhones.some(p => p.phone_number === cleanPhone)) {
      setPhoneError(t.phoneDuplicate || 'This phone already exists');
      return;
    }
    setNewPhones([...newPhones, { phone_number: cleanPhone, phone_type: newPhoneInput.phone_type }]);
    setNewPhoneInput({ phone_number: '', phone_type: 'mobile' });
    setPhoneError(null);
  };

  const removeNewPhone = (index: number) => {
    setNewPhones(newPhones.filter((_, i) => i !== index));
  };

  const toggleDeletePhone = (phoneNumber: string) => {
    const newDeleted = new Set(deletedPhones);
    if (newDeleted.has(phoneNumber)) {
      newDeleted.delete(phoneNumber);
    } else {
      newDeleted.add(phoneNumber);
    }
    setDeletedPhones(newDeleted);
  };

  const addNewEmail = () => {
    const email = newEmailInput.email_address.trim().toLowerCase();
    if (!email) {
      setEmailError(t.emailRequired || 'Email is required');
      return;
    }
    if (!validateEmail(email)) {
      setEmailError(t.emailInvalidFormat || 'Invalid email format');
      return;
    }
    // Check for duplicates
    const existingEmails = profile?.contact?.emails || [];
    if (existingEmails.some(e => e.email_address === email) || newEmails.some(e => e.email_address === email)) {
      setEmailError(t.emailDuplicate || 'This email already exists');
      return;
    }
    setNewEmails([...newEmails, { email_address: email, email_type: newEmailInput.email_type }]);
    setNewEmailInput({ email_address: '', email_type: 'personal' });
    setEmailError(null);
  };

  const removeNewEmail = (index: number) => {
    setNewEmails(newEmails.filter((_, i) => i !== index));
  };

  const toggleDeleteEmail = (emailAddress: string) => {
    const newDeleted = new Set(deletedEmails);
    if (newDeleted.has(emailAddress)) {
      newDeleted.delete(emailAddress);
    } else {
      newDeleted.add(emailAddress);
    }
    setDeletedEmails(newDeleted);
  };

  const saveSection = () => {
    // Validate City/Country for personal section
    if (editingSection === 'personal') {
      const cityEdited = editedFields['Birth City'] !== undefined;
      const countryEdited = editedFields['Birth Country'] !== undefined;

      if (cityEdited || countryEdited) {
        const cityValue = editedFields['Birth City']?.newValue || profile?.personal?.birth_city || '';
        const countryValue = editedFields['Birth Country']?.newValue || profile?.personal?.birth_country || '';

        if (cityValue && !countryValue) {
          setSectionError('Please select a country of birth');
          return;
        }
        if (countryValue && !cityValue) {
          setSectionError('Please enter a city of birth');
          return;
        }
      }
    }

    // Save changes to pending
    const actualChanges: EditedFields = {};
    Object.keys(editedFields).forEach(key => {
      const field = editedFields[key];
      const originalStr = field.originalValue || '';
      if (field.newValue !== originalStr) {
        actualChanges[key] = field;
      }
    });

    if (Object.keys(actualChanges).length > 0) {
      setPendingChanges(prev => ({ ...prev, ...actualChanges }));
    }

    // Handle contact section changes
    if (editingSection === 'contact') {
      // Validate: if deleting login phone, must select new one
      const currentLoginPhone = profile?.contact?.phones?.find(p => p.is_primary_for_login)?.phone_number;
      if (currentLoginPhone && deletedPhones.has(currentLoginPhone) && !newLoginPhone) {
        setSectionError(t.mustSelectNewLoginPhone || 'You must select a new login phone before deleting the current one');
        return;
      }
      // Validate: if deleting login email, must select new one
      const currentLoginEmail = profile?.contact?.emails?.find(e => e.is_primary_for_login)?.email_address;
      if (currentLoginEmail && deletedEmails.has(currentLoginEmail) && !newLoginEmail) {
        setSectionError(t.mustSelectNewLoginEmail || 'You must select a new login email before deleting the current one');
        return;
      }

      const hasContactChanges = newPhones.length > 0 || deletedPhones.size > 0 || newEmails.length > 0 || deletedEmails.size > 0 || newLoginPhone || newLoginEmail;
      if (hasContactChanges) {
        setPendingContactChanges({
          newPhones: [...newPhones],
          deletedPhones: Array.from(deletedPhones),
          newEmails: [...newEmails],
          deletedEmails: Array.from(deletedEmails),
          newLoginPhone: newLoginPhone,
          newLoginEmail: newLoginEmail,
        });
      }
      // Reset contact state
      setNewPhones([]);
      setDeletedPhones(new Set());
      setNewEmails([]);
      setDeletedEmails(new Set());
      setNewPhoneInput({ phone_number: '', phone_type: 'mobile' });
      setNewEmailInput({ email_address: '', email_type: 'personal' });
      setPhoneError(null);
      setEmailError(null);
      setNewLoginPhone(null);
      setNewLoginEmail(null);
    }

    setEditingSection(null);
    setEditedFields({});
    setSectionError(null);
  };

  const handleFieldChange = (fieldKey: string, newValue: string, originalValue: string | null | undefined) => {
    const wasBlank = !originalValue || originalValue.trim() === '';
    setEditedFields(prev => ({
      ...prev,
      [fieldKey]: { originalValue, newValue, wasBlank }
    }));
    setSectionError(null);
  };

  const getEditedValue = (fieldKey: string, originalValue: string | null | undefined): string => {
    // First check current section edits
    if (editedFields[fieldKey] !== undefined) {
      return editedFields[fieldKey].newValue;
    }
    // Then check pending changes
    if (pendingChanges[fieldKey] !== undefined) {
      return pendingChanges[fieldKey].newValue;
    }
    return originalValue || '';
  };

  const getDisplayValue = (fieldKey: string, originalValue: string | null | undefined): string | null | undefined => {
    // Show pending changes in display mode
    if (pendingChanges[fieldKey] !== undefined) {
      return pendingChanges[fieldKey].newValue;
    }
    return originalValue;
  };

  const hasPendingChanges = (): boolean => {
    return Object.keys(pendingChanges).length > 0 || pendingContactChanges !== null;
  };

  const isFieldChanged = (fieldKey: string): boolean => {
    return pendingChanges[fieldKey] !== undefined;
  };

  const handleSubmitForApproval = async () => {
    if (!hasPendingChanges()) return;

    setIsSubmitting(true);

    // Build the email content
    const changesForBlankFields: string[] = [];
    const changesForExistingFields: string[] = [];

    Object.keys(pendingChanges).forEach(key => {
      const field = pendingChanges[key];
      if (field.wasBlank) {
        changesForBlankFields.push(`- ${key}: "${field.newValue}"`);
      } else {
        changesForExistingFields.push(`- ${key}: "${field.originalValue}" -> "${field.newValue}"`);
      }
    });

    const userEmail = profile?.contact?.emails?.find(e => e.is_primary_for_login)?.email_address ||
                      profile?.contact?.emails?.[0]?.email_address ||
                      'Unknown';
    const userName = getDisplayValue('Full Name', profile?.personal?.full_name) || 'Unknown';

    let emailBody = `Profile Update Request\n\n`;
    emailBody += `User: ${userName}\n`;
    emailBody += `Email: ${userEmail}\n\n`;

    if (changesForBlankFields.length > 0) {
      emailBody += `New data to be added:\n${changesForBlankFields.join('\n')}\n\n`;
    }

    if (changesForExistingFields.length > 0) {
      emailBody += `Data changes requested:\n${changesForExistingFields.join('\n')}\n\n`;
    }

    // Add contact changes
    if (pendingContactChanges) {
      if (pendingContactChanges.newPhones.length > 0) {
        emailBody += `New phones to add:\n`;
        pendingContactChanges.newPhones.forEach(p => {
          emailBody += `- ${p.phone_number} (${p.phone_type})\n`;
        });
        emailBody += `\n`;
      }
      if (pendingContactChanges.deletedPhones.length > 0) {
        emailBody += `Phones to remove:\n`;
        pendingContactChanges.deletedPhones.forEach(p => {
          emailBody += `- ${p}\n`;
        });
        emailBody += `\n`;
      }
      if (pendingContactChanges.newEmails.length > 0) {
        emailBody += `New emails to add:\n`;
        pendingContactChanges.newEmails.forEach(e => {
          emailBody += `- ${e.email_address} (${e.email_type})\n`;
        });
        emailBody += `\n`;
      }
      if (pendingContactChanges.deletedEmails.length > 0) {
        emailBody += `Emails to remove:\n`;
        pendingContactChanges.deletedEmails.forEach(e => {
          emailBody += `- ${e}\n`;
        });
        emailBody += `\n`;
      }
      if (pendingContactChanges.newLoginPhone) {
        emailBody += `Change login phone to: ${pendingContactChanges.newLoginPhone}\n\n`;
      }
      if (pendingContactChanges.newLoginEmail) {
        emailBody += `Change login email to: ${pendingContactChanges.newLoginEmail}\n\n`;
      }
    }

    emailBody += `Please review and update the user's profile accordingly.`;

    const mailtoLink = `mailto:mtpsv.psav@gmail.com?subject=${encodeURIComponent(`Profile Update Request - ${userName}`)}&body=${encodeURIComponent(emailBody)}`;

    // Open the mailto link
    window.location.href = mailtoLink;

    // Show success after a brief delay
    setTimeout(() => {
      setIsSubmitting(false);
      setShowSuccess(true);
      setPendingChanges({});
      setPendingContactChanges(null);
    }, 500);
  };

  const formatCPF = (cpf: string) => {
    const digits = cpf.replace(/\D/g, '');
    if (digits.length === 11) {
      return `${digits.slice(0, 3)}.${digits.slice(3, 6)}.${digits.slice(6, 9)}-${digits.slice(9)}`;
    }
    return cpf;
  };

  const renderNotDefined = () => (
    <span className="text-sm text-gray-400 italic">{t.notDefined}</span>
  );

  const renderEditableField = (
    fieldKey: string,
    currentValue: string | null | undefined,
    section: EditableSection,
    placeholder?: string
  ) => {
    const displayValue = getDisplayValue(fieldKey, currentValue);
    const isBlank = !currentValue || currentValue.trim() === '';
    const isChanged = isFieldChanged(fieldKey);

    if (editingSection !== section) {
      // Display mode
      if (!displayValue || displayValue.trim() === '') {
        return renderNotDefined();
      }
      return (
        <span className={`text-sm text-right ${isChanged ? 'text-blue-600 font-medium' : 'text-gray-900'}`}>
          {displayValue}
        </span>
      );
    }

    // Edit mode for this section
    return (
      <input
        type="text"
        value={getEditedValue(fieldKey, currentValue)}
        onChange={(e) => handleFieldChange(fieldKey, e.target.value, currentValue)}
        placeholder={placeholder || t.notDefined}
        className={`text-sm text-right border rounded-lg px-3 py-1.5 w-48 focus:outline-none focus:ring-2 focus:ring-blue-500 ${
          isBlank ? 'border-blue-300 bg-blue-50' : 'border-gray-300 bg-white'
        }`}
      />
    );
  };

  const renderSectionHeader = (title: string, section: EditableSection) => (
    <div className="flex items-center justify-between mb-4">
      <h2 className="text-lg font-bold text-gray-900">{title}</h2>
      {editingSection === section ? (
        <div className="flex items-center space-x-2">
          <button
            onClick={cancelEditingSection}
            className="p-1.5 rounded-lg text-gray-500 hover:bg-gray-100 transition-colors"
            title={t.cancelEdit}
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
          <button
            onClick={saveSection}
            className="p-1.5 rounded-lg text-green-600 hover:bg-green-50 transition-colors"
            title="Save"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </button>
        </div>
      ) : (
        <button
          onClick={() => startEditingSection(section)}
          className={`p-1.5 rounded-lg transition-colors ${
            editingSection !== null
              ? 'text-gray-300 hover:text-gray-400'
              : 'text-gray-400 hover:text-blue-600 hover:bg-blue-50'
          }`}
          title={t.edit}
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
          </svg>
        </button>
      )}
    </div>
  );

  // Loading state
  if (loading || referenceDataLoading) {
    return (
      <div className="pt-24 pb-12 max-w-2xl mx-auto px-4 sm:px-6">
        <div className="flex items-center justify-center min-h-[400px]">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
            <p className="text-sm font-bold text-gray-400 uppercase tracking-widest">Loading profile...</p>
          </div>
        </div>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="pt-24 pb-12 max-w-2xl mx-auto px-4 sm:px-6">
        <div className="flex items-center justify-center min-h-[400px]">
          <div className="text-center bg-red-50 p-8 rounded-3xl border border-red-100">
            <div className="text-4xl mb-4">&#9888;&#65039;</div>
            <p className="text-sm font-bold text-red-600 mb-2">Failed to load profile</p>
            <p className="text-xs text-gray-600">{error}</p>
            <button
              onClick={() => window.location.reload()}
              className="mt-4 px-6 py-2 bg-red-600 text-white text-sm font-bold rounded-full hover:bg-red-700"
            >
              Retry
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="pt-24 pb-12 max-w-2xl mx-auto px-4 sm:px-6">
      {/* Success Modal */}
      {showSuccess && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-8 max-w-md w-full text-center shadow-xl">
            <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg className="w-8 h-8 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h3 className="text-xl font-bold text-gray-900 mb-2">{t.changesSubmitted}</h3>
            <p className="text-sm text-gray-600 mb-6">{t.changesSubmittedDesc}</p>
            <button
              onClick={() => setShowSuccess(false)}
              className="px-6 py-2.5 bg-blue-600 text-white text-sm font-bold rounded-full hover:bg-blue-700 transition-colors"
            >
              OK
            </button>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <button
          onClick={onBack}
          className="flex items-center space-x-2 text-gray-600 hover:text-blue-600 transition-colors"
        >
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
          <span className="text-sm font-medium">{t.back}</span>
        </button>
        <h1 className="text-2xl font-black text-gray-900">{t.title}</h1>
        <div className="w-20"></div>
      </div>

      {/* Warning Modal when trying to edit another section */}
      {editWarning && (
        <div className="fixed inset-0 bg-black/30 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 max-w-sm w-full shadow-xl">
            <div className="flex items-center space-x-3 mb-4">
              <div className="w-10 h-10 bg-amber-100 rounded-full flex items-center justify-center flex-shrink-0">
                <svg className="w-5 h-5 text-amber-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
              </div>
              <p className="text-sm text-gray-700">{editWarning}</p>
            </div>
            <button
              onClick={() => setEditWarning(null)}
              className="w-full py-2.5 bg-amber-500 text-white text-sm font-bold rounded-full hover:bg-amber-600 transition-colors"
            >
              OK
            </button>
          </div>
        </div>
      )}

      <div className="space-y-6">
        {/* Personal Information */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          {renderSectionHeader(t.personalSection, 'personal')}
          {sectionError && editingSection === 'personal' && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-600">
              {sectionError}
            </div>
          )}
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium text-gray-500">{t.fullName}</span>
              {renderEditableField('Full Name', profile?.personal?.full_name, 'personal')}
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium text-gray-500">{t.dateOfBirth}</span>
              {editingSection === 'personal' ? (
                <input
                  type="date"
                  value={getEditedValue('Date of Birth', profile?.personal?.date_of_birth)}
                  onChange={(e) => handleFieldChange('Date of Birth', e.target.value, profile?.personal?.date_of_birth)}
                  className={`text-sm border rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                    !profile?.personal?.date_of_birth ? 'border-blue-300 bg-blue-50' : 'border-gray-300 bg-white'
                  }`}
                />
              ) : (
                (() => {
                  const displayVal = getDisplayValue('Date of Birth', profile?.personal?.date_of_birth);
                  const isChanged = isFieldChanged('Date of Birth');
                  return displayVal ? (
                    <span className={`text-sm text-right ${isChanged ? 'text-blue-600 font-medium' : 'text-gray-900'}`}>
                      {formatDateForLocale(displayVal, currentLang)}
                    </span>
                  ) : renderNotDefined();
                })()
              )}
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium text-gray-500">{t.birthCity}</span>
              {editingSection === 'personal' ? (
                <input
                  type="text"
                  value={getEditedValue('Birth City', profile?.personal?.birth_city)}
                  onChange={(e) => handleFieldChange('Birth City', e.target.value, profile?.personal?.birth_city)}
                  className={`text-sm text-right border rounded-lg px-3 py-1.5 w-48 focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                    !profile?.personal?.birth_city ? 'border-blue-300 bg-blue-50' : 'border-gray-300 bg-white'
                  }`}
                />
              ) : (
                (() => {
                  const displayVal = getDisplayValue('Birth City', profile?.personal?.birth_city);
                  const isChanged = isFieldChanged('Birth City');
                  return displayVal ? (
                    <span className={`text-sm text-right ${isChanged ? 'text-blue-600 font-medium' : 'text-gray-900'}`}>
                      {displayVal}
                    </span>
                  ) : renderNotDefined();
                })()
              )}
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium text-gray-500">{t.birthCountry}</span>
              {editingSection === 'personal' ? (
                <select
                  value={getEditedValue('Birth Country', profile?.personal?.birth_country)}
                  onChange={(e) => handleFieldChange('Birth Country', e.target.value, profile?.personal?.birth_country)}
                  className={`text-sm border rounded-lg px-3 py-1.5 w-52 focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                    !profile?.personal?.birth_country ? 'border-blue-300 bg-blue-50' : 'border-gray-300 bg-white'
                  }`}
                >
                  <option value="">--</option>
                  {countries.map(c => (
                    <option key={c.iso_code} value={c.iso_code}>{c.iso_code} - {c.name}</option>
                  ))}
                </select>
              ) : (
                (() => {
                  const displayVal = getDisplayValue('Birth Country', profile?.personal?.birth_country);
                  const isChanged = isFieldChanged('Birth Country');
                  const countryName = countries.find(c => c.iso_code === displayVal)?.name || displayVal;
                  return displayVal ? (
                    <span className={`text-sm text-right ${isChanged ? 'text-blue-600 font-medium' : 'text-gray-900'}`}>
                      {countryName}
                    </span>
                  ) : renderNotDefined();
                })()
              )}
            </div>
          </div>
        </div>

        {/* Documents */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          {renderSectionHeader(t.documentsSection, 'documents')}
          {sectionError && editingSection === 'documents' && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-600">
              {sectionError}
            </div>
          )}

          {/* Brazil Documents */}
          {(profile?.documents?.brazil || editingSection === 'documents') && (
            <div className="mb-4 pb-4 border-b border-gray-100 last:border-0 last:mb-0 last:pb-0">
              <div className="flex items-center space-x-2 mb-3">
                <span className="text-lg">&#127463;&#127479;</span>
                <span className="text-sm font-semibold text-gray-700">{t.brazilDocs}</span>
              </div>
              <div className="space-y-3 pl-7">
                {/* CPF - Always read-only, cannot be changed */}
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-500">{t.cpf}</span>
                  {profile?.documents?.brazil?.cpf ? (
                    <span className="text-sm text-gray-900 font-mono">
                      {formatCPF(profile.documents.brazil.cpf)}
                    </span>
                  ) : renderNotDefined()}
                </div>
                {/* RG Number - Editable */}
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-500">{t.rg}</span>
                  {editingSection === 'documents' ? (
                    <input
                      type="text"
                      value={getEditedValue('RG', profile?.documents?.brazil?.rg_number)}
                      onChange={(e) => handleFieldChange('RG', e.target.value, profile?.documents?.brazil?.rg_number)}
                      className={`text-sm text-right border rounded-lg px-3 py-1.5 w-40 focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                        !profile?.documents?.brazil?.rg_number ? 'border-blue-300 bg-blue-50' : 'border-gray-300 bg-white'
                      }`}
                    />
                  ) : (
                    (() => {
                      const displayVal = getDisplayValue('RG', profile?.documents?.brazil?.rg_number);
                      const isChanged = isFieldChanged('RG');
                      return displayVal ? (
                        <span className={`text-sm ${isChanged ? 'text-blue-600 font-medium' : 'text-gray-900'}`}>
                          {displayVal}
                        </span>
                      ) : renderNotDefined();
                    })()
                  )}
                </div>
                {/* RG Issuer - Editable */}
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-500">{t.rgIssuer}</span>
                  {editingSection === 'documents' ? (
                    <input
                      type="text"
                      value={getEditedValue('RG Issuer', profile?.documents?.brazil?.rg_issuer)}
                      onChange={(e) => handleFieldChange('RG Issuer', e.target.value, profile?.documents?.brazil?.rg_issuer)}
                      placeholder="SSP/SP"
                      className={`text-sm text-right border rounded-lg px-3 py-1.5 w-32 focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                        !profile?.documents?.brazil?.rg_issuer ? 'border-blue-300 bg-blue-50' : 'border-gray-300 bg-white'
                      }`}
                    />
                  ) : (
                    (() => {
                      const displayVal = getDisplayValue('RG Issuer', profile?.documents?.brazil?.rg_issuer);
                      const isChanged = isFieldChanged('RG Issuer');
                      return displayVal ? (
                        <span className={`text-sm ${isChanged ? 'text-blue-600 font-medium' : 'text-gray-900'}`}>
                          {displayVal}
                        </span>
                      ) : renderNotDefined();
                    })()
                  )}
                </div>
                {/* RG Issue Date - Editable */}
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-500">{t.rgIssuedAt}</span>
                  {editingSection === 'documents' ? (
                    <input
                      type="date"
                      value={getEditedValue('RG Issue Date', profile?.documents?.brazil?.rg_issued_at)}
                      onChange={(e) => handleFieldChange('RG Issue Date', e.target.value, profile?.documents?.brazil?.rg_issued_at)}
                      className={`text-sm border rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                        !profile?.documents?.brazil?.rg_issued_at ? 'border-blue-300 bg-blue-50' : 'border-gray-300 bg-white'
                      }`}
                    />
                  ) : (
                    (() => {
                      const displayVal = getDisplayValue('RG Issue Date', profile?.documents?.brazil?.rg_issued_at);
                      const isChanged = isFieldChanged('RG Issue Date');
                      return displayVal ? (
                        <span className={`text-sm ${isChanged ? 'text-blue-600 font-medium' : 'text-gray-900'}`}>
                          {formatDateForLocale(displayVal, currentLang)}
                        </span>
                      ) : renderNotDefined();
                    })()
                  )}
                </div>
              </div>
            </div>
          )}

          {/* USA Documents */}
          {(profile?.documents?.usa || editingSection === 'documents') && (
            <div>
              <div className="flex items-center space-x-2 mb-3">
                <span className="text-lg">&#127482;&#127480;</span>
                <span className="text-sm font-semibold text-gray-700">{t.usaDocs}</span>
              </div>
              <div className="space-y-3 pl-7">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-500">{t.ssnLast4}</span>
                  {editingSection === 'documents' ? (
                    <input
                      type="text"
                      value={getEditedValue('SSN Last 4', profile?.documents?.usa?.ssn_last4)}
                      onChange={(e) => handleFieldChange('SSN Last 4', e.target.value, profile?.documents?.usa?.ssn_last4)}
                      placeholder="0000"
                      maxLength={4}
                      className={`text-sm text-right border rounded-lg px-3 py-1.5 w-24 font-mono focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                        !profile?.documents?.usa?.ssn_last4 ? 'border-blue-300 bg-blue-50' : 'border-gray-300 bg-white'
                      }`}
                    />
                  ) : (
                    profile?.documents?.usa?.ssn_last4 ? (
                      <span className={`text-sm text-gray-900 font-mono ${isFieldChanged('SSN Last 4') ? 'text-blue-600 font-medium' : ''}`}>
                        ***-**-{getDisplayValue('SSN Last 4', profile.documents.usa.ssn_last4)}
                      </span>
                    ) : renderNotDefined()
                  )}
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-500">{t.driversLicense}</span>
                  {editingSection === 'documents' ? (
                    <input
                      type="text"
                      value={getEditedValue('Drivers License', profile?.documents?.usa?.drivers_license_number)}
                      onChange={(e) => handleFieldChange('Drivers License', e.target.value, profile?.documents?.usa?.drivers_license_number)}
                      className={`text-sm text-right border rounded-lg px-3 py-1.5 w-40 focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                        !profile?.documents?.usa?.drivers_license_number ? 'border-blue-300 bg-blue-50' : 'border-gray-300 bg-white'
                      }`}
                    />
                  ) : (
                    (profile?.documents?.usa?.drivers_license_number || profile?.documents?.usa?.drivers_license_state) ? (
                      <span className={`text-sm text-gray-900 ${isFieldChanged('Drivers License') ? 'text-blue-600 font-medium' : ''}`}>
                        {getDisplayValue('Drivers License', profile?.documents?.usa?.drivers_license_number) || ''}
                        {profile?.documents?.usa?.drivers_license_state ? ` (${profile.documents.usa.drivers_license_state})` : ''}
                      </span>
                    ) : renderNotDefined()
                  )}
                </div>
              </div>
            </div>
          )}

          {!profile?.documents?.brazil && !profile?.documents?.usa && editingSection !== 'documents' && (
            <p className="text-sm text-gray-400 italic">{t.notDefined}</p>
          )}
        </div>

        {/* Contact */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          {renderSectionHeader(t.contactSection, 'contact')}
          {sectionError && editingSection === 'contact' && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-600">
              {sectionError}
            </div>
          )}

          {/* Phones */}
          <div className="mb-6">
            <span className="text-sm font-medium text-gray-500 block mb-2">{t.phones}</span>
            <div className="space-y-2">
              {/* Existing phones */}
              {profile?.contact?.phones?.map((phone, index) => {
                const isDeleted = deletedPhones.has(phone.phone_number);
                const isPendingDelete = pendingContactChanges?.deletedPhones.includes(phone.phone_number);
                const isCurrentLogin = phone.is_primary_for_login;
                const isNewLogin = newLoginPhone === phone.phone_number;
                const isPendingNewLogin = pendingContactChanges?.newLoginPhone === phone.phone_number;
                return (
                  <div key={index} className="flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                      <span className={`text-sm ${isDeleted || isPendingDelete ? 'text-red-500 line-through' : isNewLogin || isPendingNewLogin ? 'text-green-600 font-medium' : 'text-gray-900'}`}>
                        {phone.phone_number}
                      </span>
                      {phone.phone_type && (
                        <span className={`text-xs ${isDeleted || isPendingDelete ? 'text-red-400 line-through' : 'text-gray-400'}`}>
                          ({phone.phone_type})
                        </span>
                      )}
                      {(isNewLogin || isPendingNewLogin) && !isCurrentLogin && (
                        <span className="text-xs text-green-500 bg-green-100 px-1.5 py-0.5 rounded">{t.newLogin || 'new login'}</span>
                      )}
                    </div>
                    <div className="flex items-center space-x-2">
                      {isCurrentLogin && !isNewLogin && !newLoginPhone && (
                        <div className="flex items-center space-x-1 text-blue-500" title={t.loginCredential}>
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
                          </svg>
                        </div>
                      )}
                      {editingSection === 'contact' && !isDeleted && (
                        <>
                          {/* Set as login button - only show if not current login and not deleted */}
                          {!isCurrentLogin && (
                            <button
                              onClick={() => setNewLoginPhone(isNewLogin ? null : phone.phone_number)}
                              className={`p-1 rounded ${isNewLogin ? 'text-green-600 bg-green-50' : 'text-gray-400 hover:text-blue-600 hover:bg-blue-50'}`}
                              title={isNewLogin ? t.cancelSetLogin || 'Cancel set as login' : t.setAsLogin || 'Set as login'}
                            >
                              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
                              </svg>
                            </button>
                          )}
                          {/* Delete button */}
                          <button
                            onClick={() => toggleDeletePhone(phone.phone_number)}
                            className="p-1 rounded text-red-400 hover:bg-red-50"
                            title="Delete"
                          >
                            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                          </button>
                        </>
                      )}
                      {editingSection === 'contact' && isDeleted && (
                        <button
                          onClick={() => toggleDeletePhone(phone.phone_number)}
                          className="p-1 rounded text-green-600 hover:bg-green-50"
                          title="Undo delete"
                        >
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
                          </svg>
                        </button>
                      )}
                    </div>
                  </div>
                );
              })}
              {/* New phones being added */}
              {newPhones.map((phone, index) => {
                const isNewLogin = newLoginPhone === phone.phone_number;
                return (
                  <div key={`new-${index}`} className="flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                      <span className={`text-sm font-medium ${isNewLogin ? 'text-green-600' : 'text-blue-600'}`}>{phone.phone_number}</span>
                      <span className={`text-xs ${isNewLogin ? 'text-green-400' : 'text-blue-400'}`}>({phone.phone_type})</span>
                      {isNewLogin ? (
                        <span className="text-xs text-green-500 bg-green-100 px-1.5 py-0.5 rounded">{t.newLogin || 'new login'}</span>
                      ) : (
                        <span className="text-xs text-blue-500 bg-blue-100 px-1.5 py-0.5 rounded">{t.new || 'new'}</span>
                      )}
                    </div>
                    {editingSection === 'contact' && (
                      <div className="flex items-center space-x-1">
                        {/* Set as login button */}
                        <button
                          onClick={() => setNewLoginPhone(isNewLogin ? null : phone.phone_number)}
                          className={`p-1 rounded ${isNewLogin ? 'text-green-600 bg-green-50' : 'text-gray-400 hover:text-blue-600 hover:bg-blue-50'}`}
                          title={isNewLogin ? t.cancelSetLogin || 'Cancel set as login' : t.setAsLogin || 'Set as login'}
                        >
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
                          </svg>
                        </button>
                        {/* Remove button */}
                        <button
                          onClick={() => removeNewPhone(index)}
                          className="p-1 rounded text-red-400 hover:bg-red-50"
                          title="Remove"
                        >
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                          </svg>
                        </button>
                      </div>
                    )}
                  </div>
                );
              })}
              {/* Pending new phones (only show when NOT editing, since data is restored to editable state when editing) */}
              {editingSection !== 'contact' && pendingContactChanges?.newPhones.map((phone, index) => (
                <div key={`pending-${index}`} className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <span className="text-sm text-blue-600 font-medium">{phone.phone_number}</span>
                    <span className="text-xs text-blue-400">({phone.phone_type})</span>
                    <span className="text-xs text-blue-500 bg-blue-100 px-1.5 py-0.5 rounded">{t.new || 'new'}</span>
                  </div>
                </div>
              ))}
              {/* Add new phone form */}
              {editingSection === 'contact' && (
                <div className="mt-3 p-3 bg-gray-50 rounded-lg space-y-2">
                  <div className="flex space-x-2">
                    <input
                      type="tel"
                      value={newPhoneInput.phone_number}
                      onChange={(e) => setNewPhoneInput({ ...newPhoneInput, phone_number: e.target.value })}
                      placeholder="+5511999999999"
                      className="flex-1 text-sm border border-gray-300 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    <select
                      value={newPhoneInput.phone_type}
                      onChange={(e) => setNewPhoneInput({ ...newPhoneInput, phone_type: e.target.value })}
                      className="text-sm border border-gray-300 rounded-lg px-2 py-1.5 focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      {phoneTypes.map(pt => (
                        <option key={pt.code} value={pt.code}>{(t as any)[pt.code] || pt.description}</option>
                      ))}
                    </select>
                    <button
                      onClick={addNewPhone}
                      className="px-3 py-1.5 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700"
                    >
                      {t.add || 'Add'}
                    </button>
                  </div>
                  {phoneError && (
                    <p className="text-xs text-red-500">{phoneError}</p>
                  )}
                </div>
              )}
              {(!profile?.contact?.phones || profile.contact.phones.length === 0) && newPhones.length === 0 && !pendingContactChanges?.newPhones.length && editingSection !== 'contact' && (
                renderNotDefined()
              )}
            </div>
          </div>

          {/* Emails */}
          <div>
            <span className="text-sm font-medium text-gray-500 block mb-2">{t.emails}</span>
            <div className="space-y-2">
              {/* Existing emails */}
              {profile?.contact?.emails?.map((email, index) => {
                const isDeleted = deletedEmails.has(email.email_address);
                const isPendingDelete = pendingContactChanges?.deletedEmails.includes(email.email_address);
                const isCurrentLogin = email.is_primary_for_login;
                const isNewLogin = newLoginEmail === email.email_address;
                const isPendingNewLogin = pendingContactChanges?.newLoginEmail === email.email_address;
                return (
                  <div key={index} className="flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                      <span className={`text-sm ${isDeleted || isPendingDelete ? 'text-red-500 line-through' : isNewLogin || isPendingNewLogin ? 'text-green-600 font-medium' : 'text-gray-900'}`}>
                        {email.email_address}
                      </span>
                      {email.email_type && (
                        <span className={`text-xs ${isDeleted || isPendingDelete ? 'text-red-400 line-through' : 'text-gray-400'}`}>
                          ({email.email_type})
                        </span>
                      )}
                      {(isNewLogin || isPendingNewLogin) && !isCurrentLogin && (
                        <span className="text-xs text-green-500 bg-green-100 px-1.5 py-0.5 rounded">{t.newLogin || 'new login'}</span>
                      )}
                    </div>
                    <div className="flex items-center space-x-2">
                      {isCurrentLogin && !isNewLogin && !newLoginEmail && (
                        <div className="flex items-center space-x-1 text-blue-500" title={t.loginCredential}>
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
                          </svg>
                        </div>
                      )}
                      {editingSection === 'contact' && !isDeleted && (
                        <>
                          {/* Set as login button - only show if not current login and not deleted */}
                          {!isCurrentLogin && (
                            <button
                              onClick={() => setNewLoginEmail(isNewLogin ? null : email.email_address)}
                              className={`p-1 rounded ${isNewLogin ? 'text-green-600 bg-green-50' : 'text-gray-400 hover:text-blue-600 hover:bg-blue-50'}`}
                              title={isNewLogin ? t.cancelSetLogin || 'Cancel set as login' : t.setAsLogin || 'Set as login'}
                            >
                              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
                              </svg>
                            </button>
                          )}
                          {/* Delete button */}
                          <button
                            onClick={() => toggleDeleteEmail(email.email_address)}
                            className="p-1 rounded text-red-400 hover:bg-red-50"
                            title="Delete"
                          >
                            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                          </button>
                        </>
                      )}
                      {editingSection === 'contact' && isDeleted && (
                        <button
                          onClick={() => toggleDeleteEmail(email.email_address)}
                          className="p-1 rounded text-green-600 hover:bg-green-50"
                          title="Undo delete"
                        >
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
                          </svg>
                        </button>
                      )}
                    </div>
                  </div>
                );
              })}
              {/* New emails being added */}
              {newEmails.map((email, index) => {
                const isNewLogin = newLoginEmail === email.email_address;
                return (
                  <div key={`new-${index}`} className="flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                      <span className={`text-sm font-medium ${isNewLogin ? 'text-green-600' : 'text-blue-600'}`}>{email.email_address}</span>
                      <span className={`text-xs ${isNewLogin ? 'text-green-400' : 'text-blue-400'}`}>({email.email_type})</span>
                      {isNewLogin ? (
                        <span className="text-xs text-green-500 bg-green-100 px-1.5 py-0.5 rounded">{t.newLogin || 'new login'}</span>
                      ) : (
                        <span className="text-xs text-blue-500 bg-blue-100 px-1.5 py-0.5 rounded">{t.new || 'new'}</span>
                      )}
                    </div>
                    {editingSection === 'contact' && (
                      <div className="flex items-center space-x-1">
                        {/* Set as login button */}
                        <button
                          onClick={() => setNewLoginEmail(isNewLogin ? null : email.email_address)}
                          className={`p-1 rounded ${isNewLogin ? 'text-green-600 bg-green-50' : 'text-gray-400 hover:text-blue-600 hover:bg-blue-50'}`}
                          title={isNewLogin ? t.cancelSetLogin || 'Cancel set as login' : t.setAsLogin || 'Set as login'}
                        >
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
                          </svg>
                        </button>
                        {/* Remove button */}
                        <button
                          onClick={() => removeNewEmail(index)}
                          className="p-1 rounded text-red-400 hover:bg-red-50"
                          title="Remove"
                        >
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                          </svg>
                        </button>
                      </div>
                    )}
                  </div>
                );
              })}
              {/* Pending new emails (only show when NOT editing, since data is restored to editable state when editing) */}
              {editingSection !== 'contact' && pendingContactChanges?.newEmails.map((email, index) => (
                <div key={`pending-${index}`} className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <span className="text-sm text-blue-600 font-medium">{email.email_address}</span>
                    <span className="text-xs text-blue-400">({email.email_type})</span>
                    <span className="text-xs text-blue-500 bg-blue-100 px-1.5 py-0.5 rounded">{t.new || 'new'}</span>
                  </div>
                </div>
              ))}
              {/* Add new email form */}
              {editingSection === 'contact' && (
                <div className="mt-3 p-3 bg-gray-50 rounded-lg space-y-2">
                  <div className="flex space-x-2">
                    <input
                      type="email"
                      value={newEmailInput.email_address}
                      onChange={(e) => setNewEmailInput({ ...newEmailInput, email_address: e.target.value })}
                      placeholder="email@example.com"
                      className="flex-1 text-sm border border-gray-300 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    <select
                      value={newEmailInput.email_type}
                      onChange={(e) => setNewEmailInput({ ...newEmailInput, email_type: e.target.value })}
                      className="text-sm border border-gray-300 rounded-lg px-2 py-1.5 focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      {emailTypes.map(et => (
                        <option key={et.code} value={et.code}>{(t as any)[et.code] || et.description}</option>
                      ))}
                    </select>
                    <button
                      onClick={addNewEmail}
                      className="px-3 py-1.5 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700"
                    >
                      {t.add || 'Add'}
                    </button>
                  </div>
                  {emailError && (
                    <p className="text-xs text-red-500">{emailError}</p>
                  )}
                </div>
              )}
              {(!profile?.contact?.emails || profile.contact.emails.length === 0) && newEmails.length === 0 && !pendingContactChanges?.newEmails.length && editingSection !== 'contact' && (
                renderNotDefined()
              )}
            </div>
          </div>
        </div>

        {/* Address */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          {renderSectionHeader(t.addressSection, 'address')}
          {sectionError && editingSection === 'address' && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-600">
              {sectionError}
            </div>
          )}
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium text-gray-500">{t.addressLine1}</span>
              {renderEditableField('Address Line 1', profile?.address?.line1, 'address')}
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium text-gray-500">{t.addressLine2}</span>
              {renderEditableField('Address Line 2', profile?.address?.line2, 'address')}
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium text-gray-500">{t.city}</span>
              {renderEditableField('City', profile?.address?.city, 'address')}
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium text-gray-500">{t.state}</span>
              {renderEditableField('State', profile?.address?.state, 'address')}
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium text-gray-500">{t.postalCode}</span>
              {renderEditableField('Postal Code', profile?.address?.postal_code, 'address')}
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium text-gray-500">{t.country}</span>
              {editingSection === 'address' ? (
                <select
                  value={getEditedValue('Address Country', profile?.address?.country)}
                  onChange={(e) => handleFieldChange('Address Country', e.target.value, profile?.address?.country)}
                  className={`text-sm border rounded-lg px-3 py-1.5 w-52 focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                    !profile?.address?.country ? 'border-blue-300 bg-blue-50' : 'border-gray-300 bg-white'
                  }`}
                >
                  <option value="">--</option>
                  {countries.map(c => (
                    <option key={c.iso_code} value={c.iso_code}>{c.iso_code} - {c.name}</option>
                  ))}
                </select>
              ) : (
                (() => {
                  const displayVal = getDisplayValue('Address Country', profile?.address?.country);
                  const isChanged = isFieldChanged('Address Country');
                  const countryName = countries.find(c => c.iso_code === displayVal)?.name || displayVal;
                  return displayVal ? (
                    <span className={`text-sm text-right ${isChanged ? 'text-blue-600 font-medium' : 'text-gray-900'}`}>
                      {countryName}
                    </span>
                  ) : renderNotDefined();
                })()
              )}
            </div>
          </div>
        </div>

        {/* Blockchain */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          {renderSectionHeader(t.blockchainSection, 'blockchain')}
          <div className="flex justify-between items-start">
            <span className="text-sm font-medium text-gray-500">{t.polygonAddress}</span>
            <div className="flex items-center space-x-2">
              {profile?.blockchain?.polygon_address ? (
                <>
                  <span className="text-sm text-gray-900 font-mono break-all text-right max-w-[200px] sm:max-w-none">
                    {profile.blockchain.polygon_address}
                  </span>
                  <button
                    onClick={() => copyToClipboard(profile.blockchain!.polygon_address!)}
                    className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors flex-shrink-0"
                    title={t.copyAddress}
                  >
                    {copied ? (
                      <svg className="w-4 h-4 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                    ) : (
                      <svg className="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                      </svg>
                    )}
                  </button>
                </>
              ) : (
                renderNotDefined()
              )}
            </div>
          </div>
        </div>

        {/* Bank Accounts */}
        {(profile?.accounts?.brazil || profile?.accounts?.usa) && (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            {renderSectionHeader(t.bankAccountsSection, 'accounts')}

            {/* Brazil Bank */}
            {profile?.accounts?.brazil && (
              <div className="mb-4 pb-4 border-b border-gray-100 last:border-0 last:mb-0 last:pb-0">
                <div className="flex items-center space-x-2 mb-3">
                  <span className="text-lg">&#127463;&#127479;</span>
                  <span className="text-sm font-semibold text-gray-700">{t.brazilBank}</span>
                </div>
                <div className="space-y-2 pl-7">
                  {profile.accounts.brazil.bank_code && (
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-500">{t.bankCode}</span>
                      <span className="text-sm text-gray-900">{profile.accounts.brazil.bank_code}</span>
                    </div>
                  )}
                  {profile.accounts.brazil.branch_number && (
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-500">{t.branch}</span>
                      <span className="text-sm text-gray-900">{profile.accounts.brazil.branch_number}</span>
                    </div>
                  )}
                  {profile.accounts.brazil.account_number && (
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-500">{t.accountNumber}</span>
                      <span className="text-sm text-gray-900">{profile.accounts.brazil.account_number}</span>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* USA Bank */}
            {profile?.accounts?.usa && (
              <div>
                <div className="flex items-center space-x-2 mb-3">
                  <span className="text-lg">&#127482;&#127480;</span>
                  <span className="text-sm font-semibold text-gray-700">{t.usaBank}</span>
                </div>
                <div className="space-y-2 pl-7">
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-500">{t.routingNumber}</span>
                    <span className="text-sm text-gray-900">{profile.accounts.usa.routing_number}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-500">{t.accountNumber}</span>
                    <span className="text-sm text-gray-900">{profile.accounts.usa.account_number}</span>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Submit for Approval Button - Show only when there are pending changes */}
        {hasPendingChanges() && (
          <div className="mt-8">
            {/* Show summary of pending changes */}
            <div className="mb-4 p-4 bg-blue-50 border border-blue-200 rounded-xl">
              <h3 className="text-sm font-semibold text-blue-800 mb-2">{t.pendingChanges || 'Pending Changes'}:</h3>
              <ul className="text-sm text-blue-700 space-y-1">
                {Object.keys(pendingChanges).map(key => (
                  <li key={key} className="flex justify-between">
                    <span className="font-medium">{key}:</span>
                    <span>{pendingChanges[key].wasBlank ? `"${pendingChanges[key].newValue}"` : `"${pendingChanges[key].originalValue}" → "${pendingChanges[key].newValue}"`}</span>
                  </li>
                ))}
                {/* Contact changes - new phones */}
                {pendingContactChanges?.newPhones.map((phone, index) => (
                  <li key={`new-phone-${index}`} className="flex justify-between text-blue-600">
                    <span className="font-medium">{t.phones} ({t.new || 'new'}):</span>
                    <span>{phone.phone_number} ({phone.phone_type})</span>
                  </li>
                ))}
                {/* Contact changes - deleted phones */}
                {pendingContactChanges?.deletedPhones.map((phone, index) => (
                  <li key={`del-phone-${index}`} className="flex justify-between text-red-600">
                    <span className="font-medium">{t.phones} ({t.delete || 'delete'}):</span>
                    <span className="line-through">{phone}</span>
                  </li>
                ))}
                {/* Contact changes - new emails */}
                {pendingContactChanges?.newEmails.map((email, index) => (
                  <li key={`new-email-${index}`} className="flex justify-between text-blue-600">
                    <span className="font-medium">{t.emails} ({t.new || 'new'}):</span>
                    <span>{email.email_address} ({email.email_type})</span>
                  </li>
                ))}
                {/* Contact changes - deleted emails */}
                {pendingContactChanges?.deletedEmails.map((email, index) => (
                  <li key={`del-email-${index}`} className="flex justify-between text-red-600">
                    <span className="font-medium">{t.emails} ({t.delete || 'delete'}):</span>
                    <span className="line-through">{email}</span>
                  </li>
                ))}
                {/* Login credential changes */}
                {pendingContactChanges?.newLoginPhone && (
                  <li key="new-login-phone" className="flex justify-between text-green-600">
                    <span className="font-medium">{t.newLoginPhone || 'New login phone'}:</span>
                    <span>{pendingContactChanges.newLoginPhone}</span>
                  </li>
                )}
                {pendingContactChanges?.newLoginEmail && (
                  <li key="new-login-email" className="flex justify-between text-green-600">
                    <span className="font-medium">{t.newLoginEmail || 'New login email'}:</span>
                    <span>{pendingContactChanges.newLoginEmail}</span>
                  </li>
                )}
              </ul>
            </div>
            <button
              onClick={handleSubmitForApproval}
              disabled={isSubmitting}
              className={`w-full py-3 rounded-full text-sm font-bold transition-colors ${
                !isSubmitting
                  ? 'bg-blue-600 text-white hover:bg-blue-700'
                  : 'bg-gray-200 text-gray-400 cursor-not-allowed'
              }`}
            >
              {isSubmitting ? t.submittingChanges : t.submitForApproval}
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default Settings;
