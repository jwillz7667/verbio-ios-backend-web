"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";
import AppStoreBadge from "@/components/ui/AppStoreBadge";

export default function CTA() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section className="py-24 sm:py-32 relative overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0 -z-10" aria-hidden="true">
        <div className="absolute inset-0 bg-gradient-to-br from-amber-400/10 via-transparent to-orange-warm/5 dark:from-amber-400/[0.04] dark:to-orange-warm/[0.02]" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 h-[600px] w-[600px] rounded-full bg-amber-400/[0.08] dark:bg-amber-400/[0.03] blur-[120px]" />
      </div>

      <motion.div
        ref={ref}
        initial={{ opacity: 0, y: 32 }}
        animate={inView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
        className="mx-auto max-w-4xl px-6 lg:px-8 text-center"
      >
        <h2 className="text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight text-balance">
          <span className="text-stone-900 dark:text-stone-50">
            Ready to speak the
          </span>
          <br />
          <span className="gradient-text">world&apos;s languages?</span>
        </h2>

        <p className="mt-6 text-lg text-stone-500 dark:text-stone-400 max-w-xl mx-auto text-pretty">
          Download Verbio today and start communicating across languages
          instantly. Your first 7 days of Pro are free.
        </p>

        <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
          <AppStoreBadge size="lg" />
          <div className="flex flex-col items-center gap-1">
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
            </div>
            <p className="text-xs text-stone-400 dark:text-stone-500">
              4.9 rating &middot; 12,000+ reviews
            </p>
          </div>
        </div>
      </motion.div>
    </section>
  );
}
