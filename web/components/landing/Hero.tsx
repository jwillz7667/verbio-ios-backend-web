"use client";

import { motion } from "framer-motion";
import AppStoreBadge from "@/components/ui/AppStoreBadge";

const container = {
  hidden: {},
  show: { transition: { staggerChildren: 0.12, delayChildren: 0.1 } },
};

const item = {
  hidden: { opacity: 0, y: 24 },
  show: { opacity: 1, y: 0, transition: { duration: 0.6, ease: [0.22, 1, 0.36, 1] } },
};

export default function Hero() {
  return (
    <section className="relative min-h-[100svh] flex items-center justify-center overflow-hidden pt-20">
      {/* Animated background */}
      <div className="absolute inset-0" aria-hidden="true">
        {/* Gradient mesh */}
        <div className="absolute inset-0 bg-gradient-to-br from-amber-400/[0.08] via-transparent to-orange-warm/[0.04] dark:from-amber-400/[0.04] dark:to-orange-warm/[0.02]" />

        {/* Floating orbs */}
        <motion.div
          animate={{ y: [-20, 20, -20], x: [-10, 10, -10] }}
          transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }}
          className="absolute top-1/4 left-1/4 h-[500px] w-[500px] rounded-full bg-amber-400/10 dark:bg-amber-400/[0.04] blur-[100px]"
        />
        <motion.div
          animate={{ y: [20, -20, 20], x: [10, -10, 10] }}
          transition={{ duration: 10, repeat: Infinity, ease: "easeInOut" }}
          className="absolute bottom-1/4 right-1/4 h-[400px] w-[400px] rounded-full bg-orange-warm/10 dark:bg-orange-warm/[0.03] blur-[80px]"
        />
        <motion.div
          animate={{ y: [10, -15, 10] }}
          transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
          className="absolute top-1/3 right-1/3 h-[300px] w-[300px] rounded-full bg-amber-500/[0.06] dark:bg-amber-500/[0.02] blur-[60px]"
        />

        {/* Grid pattern overlay */}
        <div
          className="absolute inset-0 opacity-[0.03] dark:opacity-[0.02]"
          style={{
            backgroundImage:
              "linear-gradient(rgba(0,0,0,0.1) 1px, transparent 1px), linear-gradient(90deg, rgba(0,0,0,0.1) 1px, transparent 1px)",
            backgroundSize: "60px 60px",
          }}
        />
      </div>

      {/* Content */}
      <motion.div
        variants={container}
        initial="hidden"
        animate="show"
        className="relative z-10 mx-auto max-w-7xl px-6 lg:px-8 text-center"
      >
        {/* Badge */}
        <motion.div variants={item} className="flex justify-center mb-6">
          <span className="inline-flex items-center gap-2 rounded-full bg-amber-400/10 dark:bg-amber-400/[0.08] border border-amber-400/20 dark:border-amber-400/10 px-4 py-1.5 text-sm font-medium text-amber-700 dark:text-amber-400">
            <span className="relative flex h-2 w-2">
              <span className="absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75 animate-ping" />
              <span className="relative inline-flex h-2 w-2 rounded-full bg-amber-500" />
            </span>
            Now available on iOS
          </span>
        </motion.div>

        {/* Headline */}
        <motion.h1
          variants={item}
          className="text-5xl sm:text-6xl md:text-7xl lg:text-8xl font-bold tracking-tight text-balance"
        >
          <span className="text-stone-900 dark:text-stone-50">Your Voice,</span>
          <br />
          <span className="gradient-text">Every Language</span>
        </motion.h1>

        {/* Subtitle */}
        <motion.p
          variants={item}
          className="mt-6 text-lg sm:text-xl text-stone-500 dark:text-stone-400 max-w-2xl mx-auto text-pretty leading-relaxed"
        >
          Speak naturally in your language and hear your words come alive in
          50+ languages with AI-powered voice translation that sounds
          human.
        </motion.p>

        {/* CTAs */}
        <motion.div
          variants={item}
          className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4"
        >
          <AppStoreBadge size="lg" />
          <a
            href="#features"
            className="group inline-flex items-center gap-2 text-sm font-medium text-stone-600 dark:text-stone-400 hover:text-amber-600 dark:hover:text-amber-400 transition-colors"
          >
            See how it works
            <svg
              className="h-4 w-4 transition-transform group-hover:translate-y-0.5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
            </svg>
          </a>
        </motion.div>

        {/* Social proof */}
        <motion.div
          variants={item}
          className="mt-14 flex flex-col items-center gap-3"
        >
          <div className="flex -space-x-2">
            {[
              "bg-amber-400",
              "bg-orange-warm",
              "bg-amber-600",
              "bg-coral-soft",
              "bg-amber-500",
            ].map((color, i) => (
              <div
                key={i}
                className={`h-8 w-8 rounded-full ${color} border-2 border-cream dark:border-black ring-0`}
              />
            ))}
          </div>
          <p className="text-sm text-stone-500 dark:text-stone-400">
            Loved by <span className="font-semibold text-stone-700 dark:text-stone-200">12,000+</span> users worldwide
          </p>
          <div className="flex gap-0.5">
            {[...Array(5)].map((_, i) => (
              <svg
                key={i}
                className="h-4 w-4 text-amber-400"
                fill="currentColor"
                viewBox="0 0 24 24"
              >
                <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
              </svg>
            ))}
            <span className="ml-1.5 text-sm font-medium text-stone-600 dark:text-stone-300">
              4.9
            </span>
          </div>
        </motion.div>

        {/* Phone mockup */}
        <motion.div
          variants={item}
          className="relative mt-16 mx-auto max-w-xs sm:max-w-sm"
        >
          <div className="relative mx-auto w-[280px] sm:w-[320px]">
            {/* Phone frame */}
            <div className="relative rounded-[3rem] border-[6px] border-stone-800 dark:border-stone-200 bg-stone-900 dark:bg-stone-100 shadow-2xl shadow-stone-900/20 dark:shadow-white/10 overflow-hidden aspect-[9/19.5]">
              {/* Dynamic Island */}
              <div className="absolute top-3 left-1/2 -translate-x-1/2 w-28 h-7 bg-black dark:bg-stone-900 rounded-full z-20" />

              {/* Screen content */}
              <div className="absolute inset-0 bg-gradient-to-br from-amber-400/20 via-cream to-orange-warm/10 dark:from-amber-400/10 dark:via-stone-900 dark:to-orange-warm/5">
                <div className="pt-14 px-5">
                  <div className="h-3 w-24 rounded-full bg-stone-800/20 dark:bg-stone-200/20 mb-2" />
                  <div className="h-5 w-40 rounded-full bg-stone-800/10 dark:bg-stone-200/10 mb-6" />

                  {/* Simulated translation card */}
                  <div className="rounded-2xl bg-white/60 dark:bg-white/10 backdrop-blur-sm border border-white/40 dark:border-white/5 p-4 mb-3">
                    <div className="flex items-center gap-2 mb-2">
                      <div className="h-3 w-3 rounded-full bg-amber-400" />
                      <div className="h-2 w-14 rounded-full bg-stone-400/30" />
                    </div>
                    <div className="h-2.5 w-full rounded-full bg-stone-800/15 dark:bg-stone-200/15 mb-1.5" />
                    <div className="h-2.5 w-3/4 rounded-full bg-stone-800/10 dark:bg-stone-200/10" />
                  </div>

                  <div className="rounded-2xl bg-amber-400/15 dark:bg-amber-400/10 border border-amber-400/20 dark:border-amber-400/10 p-4 mb-3">
                    <div className="flex items-center gap-2 mb-2">
                      <div className="h-3 w-3 rounded-full bg-orange-warm" />
                      <div className="h-2 w-14 rounded-full bg-amber-600/30" />
                    </div>
                    <div className="h-2.5 w-full rounded-full bg-amber-700/15 mb-1.5" />
                    <div className="h-2.5 w-2/3 rounded-full bg-amber-700/10" />
                  </div>

                  {/* Mic button */}
                  <div className="flex justify-center mt-4">
                    <div className="h-14 w-14 rounded-full bg-gradient-to-br from-amber-400 to-orange-warm shadow-lg shadow-amber-500/30 flex items-center justify-center">
                      <svg className="h-6 w-6 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round">
                        <path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z" />
                        <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
                      </svg>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Reflection glow */}
            <div className="absolute -inset-10 -z-10 bg-gradient-to-b from-amber-400/20 to-transparent rounded-full blur-3xl opacity-60" />
          </div>
        </motion.div>
      </motion.div>
    </section>
  );
}
