"use client";

import { useState, useRef } from "react";
import { motion, useInView } from "framer-motion";
import { Check, X } from "lucide-react";
import GlassCard from "@/components/ui/GlassCard";
import SectionHeading from "@/components/ui/SectionHeading";
import { PLANS, SITE } from "@/lib/constants";

type Plan = (typeof PLANS)[number];

export default function Pricing() {
  const [annual, setAnnual] = useState(true);
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section id="pricing" className="py-24 sm:py-32 relative">
      <div className="absolute inset-0 -z-10" aria-hidden="true">
        <div className="absolute bottom-0 left-1/2 -translate-x-1/2 h-[500px] w-[700px] rounded-full bg-amber-400/[0.04] dark:bg-amber-400/[0.02] blur-[120px]" />
      </div>

      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <SectionHeading
          eyebrow="Pricing"
          title="Simple, transparent pricing"
          description="Start free. Upgrade when you need more. Cancel anytime."
        />

        {/* Period toggle */}
        <div className="mt-10 flex justify-center">
          <div className="inline-flex items-center gap-3 rounded-full bg-stone-100 dark:bg-stone-800/50 p-1.5 border border-stone-200/60 dark:border-white/[0.06]">
            <button
              onClick={() => setAnnual(false)}
              className={`rounded-full px-5 py-2 text-sm font-medium transition-all ${
                !annual
                  ? "bg-white dark:bg-stone-700 text-stone-900 dark:text-stone-50 shadow-sm"
                  : "text-stone-500 dark:text-stone-400 hover:text-stone-700 dark:hover:text-stone-300"
              }`}
            >
              Monthly
            </button>
            <button
              onClick={() => setAnnual(true)}
              className={`rounded-full px-5 py-2 text-sm font-medium transition-all flex items-center gap-2 ${
                annual
                  ? "bg-white dark:bg-stone-700 text-stone-900 dark:text-stone-50 shadow-sm"
                  : "text-stone-500 dark:text-stone-400 hover:text-stone-700 dark:hover:text-stone-300"
              }`}
            >
              Yearly
              <span className="inline-flex items-center rounded-full bg-success/10 px-2 py-0.5 text-xs font-semibold text-success">
                Save 33%
              </span>
            </button>
          </div>
        </div>

        {/* Cards */}
        <div
          ref={ref}
          className="mt-12 grid grid-cols-1 gap-6 lg:grid-cols-3 lg:gap-8 items-start"
        >
          {PLANS.map((plan, index) => {
            const price = annual ? plan.yearlyPrice : plan.monthlyPrice;
            const period = annual ? "/year" : "/month";
            const isFree = plan.tier === "free";
            const hasFreeTrial = annual && !isFree;

            return (
              <motion.div
                key={plan.name}
                initial={{ opacity: 0, y: 32 }}
                animate={inView ? { opacity: 1, y: 0 } : {}}
                transition={{
                  duration: 0.5,
                  delay: index * 0.1,
                  ease: [0.22, 1, 0.36, 1],
                }}
              >
                <GlassCard
                  variant={plan.highlighted ? "elevated" : "standard"}
                  className={`relative p-8 ${
                    plan.highlighted
                      ? "ring-2 ring-amber-400/60 dark:ring-amber-400/40"
                      : ""
                  }`}
                >
                  {"badge" in plan && plan.badge && (
                    <span className="absolute -top-3 left-6 inline-flex items-center rounded-full bg-gradient-to-r from-amber-400 to-orange-warm px-3.5 py-1 text-xs font-bold text-white shadow-lg shadow-amber-500/25">
                      {plan.badge}
                    </span>
                  )}

                  <h3 className="text-lg font-semibold text-stone-900 dark:text-stone-50">
                    {plan.name}
                  </h3>
                  <p className="mt-1 text-sm text-stone-500 dark:text-stone-400">
                    {plan.description}
                  </p>

                  <div className="mt-6 flex items-baseline gap-1">
                    <span className="text-4xl font-bold tracking-tight text-stone-900 dark:text-stone-50">
                      {isFree ? "Free" : `$${price}`}
                    </span>
                    {!isFree && (
                      <span className="text-sm text-stone-500 dark:text-stone-400">
                        {period}
                      </span>
                    )}
                  </div>

                  {hasFreeTrial && (
                    <p className="mt-2 text-sm font-medium text-success">
                      7-day free trial included
                    </p>
                  )}

                  <a
                    href={SITE.appStoreUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className={`mt-6 block w-full rounded-xl py-3 text-center text-sm font-semibold transition-all ${
                      plan.highlighted
                        ? "bg-gradient-to-r from-amber-400 to-amber-500 text-stone-900 shadow-lg shadow-amber-500/25 hover:shadow-amber-500/40 hover:brightness-105"
                        : "bg-stone-100 dark:bg-stone-800 text-stone-700 dark:text-stone-200 hover:bg-stone-200 dark:hover:bg-stone-700"
                    }`}
                  >
                    {plan.cta}
                  </a>

                  <ul className="mt-8 space-y-3">
                    {plan.features.map((feat) => (
                      <li
                        key={feat.text}
                        className="flex items-start gap-3 text-sm"
                      >
                        {feat.included ? (
                          <Check className="mt-0.5 h-4 w-4 shrink-0 text-success" />
                        ) : (
                          <X className="mt-0.5 h-4 w-4 shrink-0 text-stone-300 dark:text-stone-600" />
                        )}
                        <span
                          className={
                            feat.included
                              ? "text-stone-700 dark:text-stone-300"
                              : "text-stone-400 dark:text-stone-600"
                          }
                        >
                          {feat.text}
                        </span>
                      </li>
                    ))}
                  </ul>
                </GlassCard>
              </motion.div>
            );
          })}
        </div>

        <p className="mt-10 text-center text-xs text-stone-400 dark:text-stone-500">
          Prices in USD. Subscriptions auto-renew. Cancel anytime.{" "}
          <a
            href="/terms"
            className="underline underline-offset-2 hover:text-stone-600 dark:hover:text-stone-300"
          >
            Terms apply
          </a>
          .
        </p>
      </div>
    </section>
  );
}
