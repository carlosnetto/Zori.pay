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

import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import Navbar from './components/Navbar';
import Hero from './components/Hero';
import Problem from './components/Problem';
import Solution from './components/Solution';
import HowItWorks from './components/HowItWorks';
import FAQ from './components/FAQ';
import AboutUs from './components/AboutUs';
import Footer from './components/Footer';
import LoginModal from './components/LoginModal';
import PasskeyVerify from './components/PasskeyVerify';
import Dashboard from './components/Dashboard';
import Onboarding from './components/Onboarding';
import { Language, translations } from './translations';
import { authService } from './services/auth';

type ViewState = 'landing' | 'onboarding' | 'dashboard';

const App: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [currentLang, setCurrentLang] = useState<Language>('en');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isLoginModalOpen, setIsLoginModalOpen] = useState(false);
  const [showPasskeyVerify, setShowPasskeyVerify] = useState(false);

  // App State
  const [currentView, setCurrentView] = useState<ViewState>('landing');
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [loading, setLoading] = useState(true);

  // Check authentication on mount
  useEffect(() => {
    const checkAuth = async () => {
      const authenticated = authService.isAuthenticated();
      setIsLoggedIn(authenticated);
      if (authenticated) {
        setCurrentView('dashboard');
      }
      setLoading(false);
    };
    checkAuth();
  }, []);

  // Handle OAuth callback
  useEffect(() => {
    const handleOAuthCallback = async () => {
      const params = new URLSearchParams(location.search);
      const code = params.get('code');
      const state = params.get('state');

      console.log('[OAuth Callback] Checking for code and state...', { code: !!code, state: !!state });

      if (code && state) {
        console.log('[OAuth Callback] Found code and state, processing...');
        try {
          console.log('[OAuth Callback] Calling handleGoogleCallback...');
          const result = await authService.handleGoogleCallback(code);
          console.log('[OAuth Callback] Google callback success:', result);

          // Clear URL parameters and go to home
          navigate('/', { replace: true });

          // Show passkey verification
          console.log('[OAuth Callback] Setting showPasskeyVerify to true');
          setShowPasskeyVerify(true);
          console.log('[OAuth Callback] showPasskeyVerify state updated');
        } catch (error) {
          console.error('[OAuth Callback] ERROR:', error);
          alert('Login failed. Please try again.');
          navigate('/', { replace: true });
        }
      } else {
        console.log('[OAuth Callback] No code/state in URL, skipping callback handling');
      }
    };

    handleOAuthCallback();
  }, [location, navigate]);

  // Scroll to top on view change
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [currentView]);

  const t = translations[currentLang].cta;

  const openModal = () => setIsModalOpen(true);
  const openLoginModal = () => setIsLoginModalOpen(true);
  const openOnboarding = () => setCurrentView('onboarding');

  const handleLoginSuccess = (isNewUser: boolean) => {
    setIsLoggedIn(true);
    setIsLoginModalOpen(false);
    if (isNewUser) {
      setCurrentView('onboarding');
    } else {
      setCurrentView('dashboard');
    }
  };

  const handleSignOut = async () => {
    await authService.logout();
    setIsLoggedIn(false);
    setCurrentView('landing');
  };

  const handlePasskeySuccess = () => {
    setShowPasskeyVerify(false);
    setIsLoggedIn(true);
    // Check if user is new (simplified - in real app, API would tell us)
    const user = authService.getUser();
    if (user) {
      // For now, assume existing user
      setCurrentView('dashboard');
    }
  };

  const handlePasskeyCancel = () => {
    setShowPasskeyVerify(false);
    authService.logout();
  };

  const handleGoHome = () => {
    // Used after successful KYC submission to reset or go back to main
    // For this demo, we can just reload the page or go to landing
    window.location.reload();
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="w-16 h-16 bg-blue-600 rounded-lg flex items-center justify-center mx-auto mb-4 animate-pulse">
            <span className="text-white font-bold text-2xl">Z</span>
          </div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen">
      <Navbar
        currentLang={currentLang}
        onLanguageChange={setCurrentLang}
        onGetZori={openModal}
        onOpenAccount={openOnboarding}
        onSignIn={openLoginModal}
        isLoggedIn={isLoggedIn}
        onSignOut={handleSignOut}
        currentView={currentView}
      />

      <main>
        {currentView === 'landing' && (
          <>
            <Hero currentLang={currentLang} onGetZori={openModal} />
            <Problem currentLang={currentLang} />
            <Solution currentLang={currentLang} />
            <HowItWorks currentLang={currentLang} />
            <section className="py-24 bg-blue-600 relative overflow-hidden">
              <div className="absolute top-0 left-0 w-full h-full opacity-10">
                <div className="absolute top-10 left-10 w-64 h-64 bg-white rounded-full blur-3xl"></div>
                <div className="absolute bottom-10 right-10 w-96 h-96 bg-white rounded-full blur-3xl"></div>
              </div>
              <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center relative z-10">
                <h2 className="text-4xl md:text-5xl font-extrabold text-white mb-6">{t.title}</h2>
                <p className="text-xl text-blue-100 mb-10 font-medium">{t.subtitle}</p>
                <button
                  onClick={openModal}
                  className="bg-white text-blue-600 hover:bg-blue-50 px-10 py-5 rounded-2xl text-xl font-bold transition-all shadow-2xl active:scale-95"
                >
                  {t.btn}
                </button>
              </div>
            </section>
            <FAQ currentLang={currentLang} />
            <AboutUs currentLang={currentLang} />
          </>
        )}

        {currentView === 'dashboard' && (
          <Dashboard currentLang={currentLang} />
        )}

        {currentView === 'onboarding' && (
          <Onboarding currentLang={currentLang} onGoHome={handleGoHome} />
        )}
      </main>

      <Footer currentLang={currentLang} />

      {/* "Coming Soon" Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setIsModalOpen(false)}></div>
          <div className="bg-white rounded-3xl p-8 max-w-md w-full relative z-10 shadow-2xl animate-in fade-in zoom-in duration-200">
            <button onClick={() => setIsModalOpen(false)} className="absolute top-4 right-4 p-2 hover:bg-gray-100 rounded-full transition-colors">
              <svg className="w-6 h-6 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
            <div className="w-16 h-16 bg-blue-100 text-blue-600 rounded-2xl flex items-center justify-center mb-6 mx-auto">
              <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <h3 className="text-2xl font-bold text-center mb-4 text-gray-900">{translations[currentLang].modal.title}</h3>
            <p className="text-gray-600 text-center leading-relaxed mb-8">
              {translations[currentLang].modal.desc}
            </p>
            <button
              onClick={() => setIsModalOpen(false)}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-4 rounded-xl transition-colors"
            >
              {translations[currentLang].modal.close}
            </button>
          </div>
        </div>
      )}

      {/* Login Modal */}
      {isLoginModalOpen && (
        <LoginModal
          currentLang={currentLang}
          onClose={() => setIsLoginModalOpen(false)}
          onLoginSuccess={handleLoginSuccess}
        />
      )}

      {/* Passkey Verification Modal */}
      {showPasskeyVerify && (
        <PasskeyVerify
          currentLang={currentLang}
          onSuccess={handlePasskeySuccess}
          onCancel={handlePasskeyCancel}
        />
      )}
    </div>
  );
};

export default App;
