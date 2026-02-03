
import React, { useState } from 'react';
import { Language, translations } from '../translations';
import { formatCPF, validateCPF, getDigitsOnly } from '../utils/cpfValidator';
import axios from 'axios';

interface OnboardingProps {
  currentLang: Language;
  onGoHome: () => void;
}

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/v1';

const Onboarding: React.FC<OnboardingProps> = ({ currentLang, onGoHome }) => {
  const t = translations[currentLang].kyc;
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [cpf, setCpf] = useState('');
  const [cpfError, setCpfError] = useState('');
  const [email, setEmail] = useState('');
  const [emailError, setEmailError] = useState('');

  // Email validation regex - allows + character
  const emailRegex = /^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$/;

  const validateEmail = (email: string): boolean => {
    return emailRegex.test(email);
  };

  const handleCpfChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const formatted = formatCPF(e.target.value);
    setCpf(formatted);
    // Clear error when user starts typing
    if (cpfError) setCpfError('');
  };

  const handleCpfBlur = () => {
    const digits = getDigitsOnly(cpf);
    if (digits.length > 0 && digits.length < 11) {
      setCpfError(t.cpfErrorIncomplete);
    } else if (digits.length === 11 && !validateCPF(cpf)) {
      setCpfError(t.cpfErrorInvalid);
    }
  };

  const handleEmailChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setEmail(e.target.value);
    // Clear error when user starts typing
    if (emailError) setEmailError('');
  };

  const handleEmailBlur = () => {
    if (email.length > 0 && !validateEmail(email)) {
      setEmailError(t.emailError);
    }
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    // Validate CPF before submission
    if (!validateCPF(cpf)) {
      setCpfError(t.cpfErrorInvalid);
      return;
    }

    // Validate email before submission
    if (!validateEmail(email)) {
      setEmailError(t.emailError);
      return;
    }

    setLoading(true);
    setError('');

    try {
      const formData = new FormData(e.currentTarget);

      // Replace formatted CPF with digits only
      formData.set('cpf', getDigitsOnly(cpf));

      const response = await axios.post(`${API_URL}/kyc/open-account-br`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      console.log('Account created:', response.data);
      setSubmitted(true);
    } catch (err: any) {
      console.error('Submission error:', err);
      const errorMsg = err.response?.data?.message || err.message || 'Failed to create account. Please try again.';
      setError(errorMsg);
    } finally {
      setLoading(false);
    }
  };

  if (submitted) {
    return (
      <div className="min-h-screen pt-24 pb-12 px-4 flex items-center justify-center">
        <div className="bg-white p-8 rounded-3xl shadow-xl max-w-md w-full text-center animate-in fade-in slide-in-from-bottom-4">
          <div className="w-20 h-20 bg-green-100 text-green-600 rounded-full flex items-center justify-center mx-auto mb-6">
            <svg className="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">{t.successTitle}</h2>
          <p className="text-lg text-gray-600 mb-6">{t.successDesc}</p>
          <div className="bg-blue-50 border border-blue-100 rounded-xl p-4 text-left mb-8">
            <p className="text-sm text-blue-800 leading-relaxed">
              {t.successNote}
            </p>
          </div>
          <button 
            onClick={onGoHome}
            className="w-full bg-gray-900 text-white font-bold py-4 rounded-xl hover:bg-black transition-colors"
          >
            {t.backHome}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="pt-24 pb-20 max-w-2xl mx-auto px-4 sm:px-6">
      <div className="mb-8">
        <h2 className="text-3xl font-extrabold text-gray-900 mb-2">{t.title}</h2>
        <p className="text-gray-600">{t.subtitle}</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-8">
        {/* Country */}
        <div className="bg-gray-50 p-6 rounded-2xl border border-gray-100">
            <label className="block text-sm font-bold text-gray-700 mb-2">{t.country}</label>
            <select disabled className="w-full bg-white border border-gray-200 rounded-xl px-4 py-3 text-gray-900 font-medium focus:ring-2 focus:ring-blue-500 focus:outline-none opacity-60 cursor-not-allowed">
                <option value="br">{t.brazil}</option>
            </select>
        </div>

        {/* Personal Info */}
        <div className="space-y-4">
            <div>
                <label className="block text-sm font-bold text-gray-700 mb-2">{t.fullName}</label>
                <input required type="text" name="full_name" className="w-full bg-white border border-gray-200 rounded-xl px-4 py-3 focus:ring-2 focus:ring-blue-500 focus:outline-none" />
            </div>
            <div>
                <label className="block text-sm font-bold text-gray-700 mb-2">{t.motherName}</label>
                <input required type="text" name="mother_name" className="w-full bg-white border border-gray-200 rounded-xl px-4 py-3 focus:ring-2 focus:ring-blue-500 focus:outline-none" />
            </div>
            <div>
                <label className="block text-sm font-bold text-gray-700 mb-2">{t.cpf}</label>
                <input
                    required
                    type="text"
                    placeholder="000.000.000-00"
                    value={cpf}
                    onChange={handleCpfChange}
                    onBlur={handleCpfBlur}
                    className={`w-full bg-white border ${cpfError ? 'border-red-500' : 'border-gray-200'} rounded-xl px-4 py-3 focus:ring-2 ${cpfError ? 'focus:ring-red-500' : 'focus:ring-blue-500'} focus:outline-none`}
                />
                {cpfError && (
                    <p className="mt-1 text-sm text-red-600 flex items-center">
                        <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                        </svg>
                        {cpfError}
                    </p>
                )}
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label className="block text-sm font-bold text-gray-700 mb-2">{t.email}</label>
                    <input
                        required
                        type="email"
                        name="email"
                        value={email}
                        onChange={handleEmailChange}
                        onBlur={handleEmailBlur}
                        className={`w-full bg-white border ${emailError ? 'border-red-500' : 'border-gray-200'} rounded-xl px-4 py-3 focus:ring-2 ${emailError ? 'focus:ring-red-500' : 'focus:ring-blue-500'} focus:outline-none`}
                    />
                    {emailError && (
                        <p className="mt-1 text-sm text-red-600 flex items-center">
                            <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                            </svg>
                            {emailError}
                        </p>
                    )}
                </div>
                <div>
                    <label className="block text-sm font-bold text-gray-700 mb-2">{t.phone}</label>
                    <input required type="tel" name="phone" placeholder="+5511999999999" className="w-full bg-white border border-gray-200 rounded-xl px-4 py-3 focus:ring-2 focus:ring-blue-500 focus:outline-none" />
                </div>
            </div>
        </div>

        {/* Uploads */}
        <div className="space-y-6">
            <h3 className="text-lg font-bold text-gray-900 pt-4">{t.uploadTitle}</h3>

            {/* CNH Upload Options: PDF OR Front/Back */}
            <div className="relative grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Left side: CNH PDF */}
                <div className="border-2 border-dashed border-gray-200 rounded-2xl p-6 text-center hover:bg-gray-50 transition-colors cursor-pointer group">
                    <svg className="w-8 h-8 mx-auto text-gray-400 group-hover:text-blue-500 mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" /></svg>
                    <span className="text-sm font-medium text-gray-600 group-hover:text-gray-900 block mb-2">{t.idPdf}</span>
                    <input type="file" name="cnh_pdf" accept="application/pdf" className="text-xs text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-xs file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100" />
                </div>

                {/* OR vertical line divider with vertical text - hidden on mobile, shown on desktop */}
                <div className="hidden md:flex absolute left-1/2 -translate-x-1/2 top-0 bottom-0 w-8 items-center justify-center pointer-events-none z-10">
                    <div className="h-3/4 flex items-center justify-center relative">
                        <div className="absolute inset-y-0 left-1/2 w-px bg-gray-300"></div>
                        <span className="text-xs font-semibold text-gray-500 bg-white px-1 z-10 rotate-90 whitespace-nowrap">{t.or}</span>
                    </div>
                </div>

                {/* Right side: Front + Back side by side */}
                <div className="flex items-stretch gap-2">
                    {/* CNH Front */}
                    <div className="flex-1 min-w-0 border-2 border-dashed border-gray-200 rounded-2xl p-3 text-center hover:bg-gray-50 transition-colors cursor-pointer group">
                        <svg className="w-5 h-5 mx-auto text-gray-400 group-hover:text-blue-500 mb-1" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 7l-2-2H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3l-2-2h-4H10z" /></svg>
                        <span className="text-xs font-medium text-gray-600 group-hover:text-gray-900 block mb-1 truncate">{t.idFront}</span>
                        <input type="file" name="cnh_front" accept="image/*" className="w-full text-xs text-gray-400 file:mr-1 file:py-1 file:px-2 file:rounded-full file:border-0 file:text-xs file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100" />
                    </div>

                    {/* CNH Back */}
                    <div className="flex-1 min-w-0 border-2 border-dashed border-gray-200 rounded-2xl p-3 text-center hover:bg-gray-50 transition-colors cursor-pointer group">
                        <svg className="w-5 h-5 mx-auto text-gray-400 group-hover:text-blue-500 mb-1" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 7l-2-2H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3l-2-2h-4H10z" /></svg>
                        <span className="text-xs font-medium text-gray-600 group-hover:text-gray-900 block mb-1 truncate">{t.idBack}</span>
                        <input type="file" name="cnh_back" accept="image/*" className="w-full text-xs text-gray-400 file:mr-1 file:py-1 file:px-2 file:rounded-full file:border-0 file:text-xs file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100" />
                    </div>
                </div>
            </div>

            {/* Selfie and Address Proof with AND divider */}
            <div className="relative grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="border-2 border-dashed border-gray-200 rounded-2xl p-6 text-center hover:bg-gray-50 transition-colors cursor-pointer group">
                    <svg className="w-8 h-8 mx-auto text-gray-400 group-hover:text-blue-500 mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                    <span className="text-sm font-medium text-gray-600 group-hover:text-gray-900 block mb-2">{t.selfie}</span>
                    <input required type="file" name="selfie" accept="image/*" className="text-xs text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-xs file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100" />
                </div>

                {/* AND vertical line divider with vertical text - hidden on mobile, shown on desktop */}
                <div className="hidden md:flex absolute left-1/2 -translate-x-1/2 top-0 bottom-0 w-8 items-center justify-center pointer-events-none z-10">
                    <div className="h-3/4 flex items-center justify-center relative">
                        <div className="absolute inset-y-0 left-1/2 w-px bg-gray-300"></div>
                        <span className="text-xs font-semibold text-gray-500 bg-white px-1 z-10 rotate-90 whitespace-nowrap">{t.and}</span>
                    </div>
                </div>

                <div className="border-2 border-dashed border-gray-200 rounded-2xl p-6 text-center hover:bg-gray-50 transition-colors cursor-pointer group">
                    <svg className="w-8 h-8 mx-auto text-gray-400 group-hover:text-blue-500 mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" /></svg>
                    <span className="text-sm font-medium text-gray-600 group-hover:text-gray-900 block mb-2">{t.proofAddr}</span>
                    <input required type="file" name="proof_of_address" className="text-xs text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-xs file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100" />
                </div>
            </div>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-xl p-4 text-red-800">
            <p className="font-medium">{error}</p>
          </div>
        )}

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed text-white font-bold py-4 rounded-xl text-lg transition-all shadow-xl shadow-blue-200 active:scale-95 mt-8 flex items-center justify-center"
        >
          {loading ? (
            <>
              <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Processing...
            </>
          ) : (
            t.submit
          )}
        </button>
      </form>
    </div>
  );
};

export default Onboarding;
