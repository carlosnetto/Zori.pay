
import React, { useState, useEffect, useRef } from 'react';
import { Language, languages, translations } from '../translations';
import { authService } from '../services/auth';

interface NavbarProps {
  currentLang: Language;
  onLanguageChange: (lang: Language) => void;
  onGetZori: () => void;
  onOpenAccount: () => void;
  onSignIn: () => void;
  isLoggedIn: boolean;
  onSignOut: () => void;
  currentView: 'landing' | 'onboarding' | 'dashboard';
}

const Navbar: React.FC<NavbarProps> = ({
  currentLang,
  onLanguageChange,
  onGetZori,
  onOpenAccount,
  onSignIn,
  isLoggedIn,
  onSignOut,
  currentView
}) => {
  const [isLangDropdownOpen, setIsLangDropdownOpen] = useState(false);
  const [isProfileDropdownOpen, setIsProfileDropdownOpen] = useState(false);
  const profileDropdownRef = useRef<HTMLDivElement>(null);
  const t = translations[currentLang].nav;

  const user = authService.getUser();

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (profileDropdownRef.current && !profileDropdownRef.current.contains(event.target as Node)) {
        setIsProfileDropdownOpen(false);
      }
    };

    if (isProfileDropdownOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isProfileDropdownOpen]);

  const scrollToSection = (e: React.MouseEvent<HTMLAnchorElement>, id: string) => {
    e.preventDefault();
    if (currentView !== 'landing') {
        window.location.href = `/#${id}`;
        return;
    }
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  };

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map(n => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  };

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-white/80 backdrop-blur-md border-b border-gray-100">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          <div className="flex items-center space-x-2 cursor-pointer" onClick={() => window.location.reload()}>
            <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-xl">Z</span>
            </div>
            <span className="text-2xl font-extrabold tracking-tight text-blue-600">zori.pay</span>
          </div>

          {currentView === 'landing' && (
            <div className="hidden lg:flex space-x-8 text-sm font-medium text-gray-600">
                <a href="#problem" onClick={(e) => scrollToSection(e, 'problem')} className="hover:text-blue-600 transition-colors">{t.problem}</a>
                <a href="#solution" onClick={(e) => scrollToSection(e, 'solution')} className="hover:text-blue-600 transition-colors">{t.solution}</a>
                <a href="#how-it-works" onClick={(e) => scrollToSection(e, 'how-it-works')} className="hover:text-blue-600 transition-colors">{t.how}</a>
                <a href="#faq" onClick={(e) => scrollToSection(e, 'faq')} className="hover:text-blue-600 transition-colors">{t.faq}</a>
                <a href="#about" onClick={(e) => scrollToSection(e, 'about')} className="hover:text-blue-600 transition-colors">{t.about}</a>
            </div>
          )}

          <div className="flex items-center space-x-4">
            {/* Language Switcher */}
            <div className="relative">
              <button
                onClick={() => setIsLangDropdownOpen(!isLangDropdownOpen)}
                className="flex items-center space-x-1 px-3 py-1 bg-gray-50 rounded-lg text-sm font-semibold hover:bg-gray-100 transition-colors border border-gray-200"
              >
                <span>{languages.find(l => l.code === currentLang)?.flag}</span>
                <span className="hidden sm:inline">{languages.find(l => l.code === currentLang)?.name}</span>
                <svg className={`w-4 h-4 transition-transform ${isLangDropdownOpen ? 'rotate-180' : ''}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </button>

              {isLangDropdownOpen && (
                <div className="absolute right-0 mt-2 w-48 bg-white border border-gray-100 rounded-xl shadow-xl overflow-hidden animate-in fade-in zoom-in duration-200 z-50">
                  {languages.map((lang) => (
                    <button
                      key={lang.code}
                      onClick={() => {
                        onLanguageChange(lang.code as Language);
                        setIsLangDropdownOpen(false);
                      }}
                      className={`w-full text-left px-4 py-3 text-sm hover:bg-blue-50 transition-colors flex items-center space-x-3 ${currentLang === lang.code ? 'bg-blue-50 text-blue-600 font-bold' : 'text-gray-700'}`}
                    >
                      <span className="text-lg">{lang.flag}</span>
                      <span>{lang.name}</span>
                    </button>
                  ))}
                </div>
              )}
            </div>

            {!isLoggedIn ? (
                <>
                    <button
                        onClick={onSignIn}
                        className="text-sm font-bold text-gray-700 hover:text-blue-600 transition-colors"
                    >
                        {t.signin}
                    </button>
                    <button
                    onClick={onOpenAccount}
                    className="bg-blue-600 hover:bg-blue-700 text-white px-5 py-2 rounded-full text-sm font-semibold transition-all shadow-md active:scale-95"
                    >
                    {t.openAccount}
                    </button>
                </>
            ) : (
                <div className="relative" ref={profileDropdownRef}>
                    <button
                        onClick={() => setIsProfileDropdownOpen(!isProfileDropdownOpen)}
                        className="flex items-center space-x-2 px-3 py-2 rounded-lg hover:bg-gray-50 transition-colors"
                    >
                        <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center">
                            <span className="text-white text-xs font-bold">
                                {user ? getInitials(user.display_name) : 'U'}
                            </span>
                        </div>
                        <svg className={`w-4 h-4 text-gray-600 transition-transform ${isProfileDropdownOpen ? 'rotate-180' : ''}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                        </svg>
                    </button>

                    {isProfileDropdownOpen && (
                        <div className="absolute right-0 mt-2 w-72 bg-white border border-gray-100 rounded-xl shadow-xl overflow-hidden animate-in fade-in zoom-in duration-200 z-50">
                            {/* User Info Section */}
                            <div className="px-4 py-3 border-b border-gray-100 bg-gray-50">
                                <div className="flex items-center space-x-3">
                                    <div className="w-12 h-12 bg-blue-600 rounded-full flex items-center justify-center flex-shrink-0">
                                        <span className="text-white text-sm font-bold">
                                            {user ? getInitials(user.display_name) : 'U'}
                                        </span>
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <p className="text-sm font-semibold text-gray-900 truncate">
                                            {user?.display_name || 'User'}
                                        </p>
                                        <p className="text-xs text-gray-500 truncate">
                                            {user?.email || 'email@example.com'}
                                        </p>
                                    </div>
                                </div>
                            </div>

                            {/* Menu Items */}
                            <div className="py-2">
                                <button
                                    onClick={() => {
                                        setIsProfileDropdownOpen(false);
                                        onSignOut();
                                    }}
                                    className="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition-colors flex items-center space-x-2"
                                >
                                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                                    </svg>
                                    <span>{t.signout}</span>
                                </button>
                            </div>
                        </div>
                    )}
                </div>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
