
import React from 'react';
import { Language, translations } from '../translations';

interface ProblemProps {
  currentLang: Language;
}

const PROBLEM_ICONS = [
  // Fees - Credit Card Icon with Slash
  <svg key="fees" className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 3l18 18" className="text-red-500" />
  </svg>,
  // Rates - Currency Change/Exchange Icon
  <svg key="rates" className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
  </svg>,
  // Security - Broken Shield/Ghost
  <svg key="stolen" className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
  </svg>,
  // Restrictions - Lock Icon
  <svg key="restricted" className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
  </svg>,
  // Plastic - Discarded Card
  <svg key="plastic" className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
  </svg>
];

const Problem: React.FC<ProblemProps> = ({ currentLang }) => {
  const t = translations[currentLang].problem;

  return (
    <section id="problem" className="py-32 bg-slate-950 relative overflow-hidden scroll-mt-20">
      {/* Decorative background elements */}
      <div className="absolute top-0 left-1/4 w-96 h-96 bg-red-500/10 rounded-full blur-[120px] -translate-y-1/2" />
      <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-amber-500/10 rounded-full blur-[120px] translate-y-1/2" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="text-center mb-24">
          <h2 className="text-sm font-bold text-red-500 uppercase tracking-[0.3em] mb-4">{t.label}</h2>
          <h3 className="text-4xl md:text-6xl font-black text-white leading-tight">
            {t.title.split(' ').map((word, i) => (
              <span key={i} className={i === t.title.split(' ').length - 1 ? "text-transparent bg-clip-text bg-gradient-to-r from-red-400 to-amber-500 italic" : ""}>
                {word}{' '}
              </span>
            ))}
          </h3>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          {t.items.map((text, idx) => (
            <div
              key={idx}
              className={`
                group p-8 rounded-3xl border transition-all duration-500
                bg-white/5 border-white/10 backdrop-blur-xl
                hover:bg-white/10 hover:border-white/20 hover:-translate-y-2
                ${idx % 2 === 0 ? 'lg:translate-y-4' : ''}
              `}
            >
              <div className="inline-flex p-3 rounded-2xl bg-gradient-to-br from-red-500/20 to-amber-500/20 text-red-400 mb-6 group-hover:scale-110 group-hover:rotate-3 transition-transform duration-500">
                {PROBLEM_ICONS[idx % PROBLEM_ICONS.length]}
              </div>
              <p className="text-xl text-gray-300 font-medium leading-relaxed group-hover:text-white transition-colors">
                {text}
              </p>
            </div>
          ))}

          {/* Styled Quote Card */}
          <div className="lg:col-span-1 bg-gradient-to-br from-red-600 to-amber-600 p-10 rounded-3xl shadow-2xl shadow-red-900/20 flex flex-col justify-center items-start relative group overflow-hidden">
            <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:scale-150 transition-transform duration-1000">
              <svg className="w-32 h-32 text-white" fill="currentColor" viewBox="0 0 24 24">
                <path d="M14.017 21L14.017 18C14.017 16.8954 14.9124 16 16.017 16H19.017C19.5693 16 20.017 15.5523 20.017 15V9C20.017 8.44772 19.5693 8 19.017 8H16.017C14.9124 8 14.017 7.10457 14.017 6V5C14.017 3.34315 15.3602 2 17.017 2H20.017C21.6739 2 23.017 3.34315 23.017 5V15C23.017 18.3137 20.3307 21 17.017 21H14.017ZM1 21L1 18C1 16.8954 1.89543 16 3 16H6C6.55228 16 7 15.5523 7 15V9C7 8.44772 6.55228 8 6 8H3C1.89543 8 1 7.10457 1 6V5C1 3.34315 2.34315 2 4 2H7C8.65685 2 10 3.34315 10 5V15C10 18.3137 7.31371 21 4 21H1Z" />
              </svg>
            </div>
            <p className="text-3xl font-black text-white italic leading-tight relative z-10">
              {t.quote}
            </p>
            <div className="mt-8 w-12 h-1.5 bg-white/30 rounded-full" />
          </div>
        </div>
      </div>
    </section>
  );
};

export default Problem;
