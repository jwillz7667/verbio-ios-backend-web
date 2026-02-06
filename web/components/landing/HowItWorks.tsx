"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";
import { Mic, Languages, Volume2 } from "lucide-react";
import SectionHeading from "@/components/ui/SectionHeading";

const STEPS = [
  {
    number: "01",
    icon: Mic,
    title: "Speak",
    description:
      "Tap the mic and speak naturally in your language. Verbio captures your voice with studio-grade accuracy.",
  },
  {
    number: "02",
    icon: Languages,
    title: "Translate",
    description:
      "Advanced neural models translate your speech in milliseconds, preserving meaning, context, and tone.",
  },
  {
    number: "03",
    icon: Volume2,
    title: "Listen",
    description:
      "Hear your translation spoken aloud in a natural AI voice that sounds human, not robotic.",
  },
];

export default function HowItWorks() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section className="py-24 sm:py-32 relative bg-stone-50/50 dark:bg-stone-900/20">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <SectionHeading
          eyebrow="How It Works"
          title="Three steps to fluency"
          description="No typing, no menus, no complexity. Just speak and let Verbio handle the rest."
        />

        <div ref={ref} className="mt-16 grid grid-cols-1 md:grid-cols-3 gap-8 lg:gap-12">
          {STEPS.map((step, index) => (
            <motion.div
              key={step.number}
              initial={{ opacity: 0, y: 32 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{
                duration: 0.5,
                delay: index * 0.15,
                ease: [0.22, 1, 0.36, 1],
              }}
              className="relative text-center"
            >
              {/* Connector line (desktop only) */}
              {index < STEPS.length - 1 && (
                <div className="hidden md:block absolute top-12 left-[calc(50%+40px)] w-[calc(100%-80px)] h-px bg-gradient-to-r from-amber-400/30 to-amber-400/10" />
              )}

              <div className="relative inline-flex">
                <div className="flex h-24 w-24 items-center justify-center rounded-3xl bg-gradient-to-br from-amber-400/15 to-orange-warm/10 dark:from-amber-400/10 dark:to-orange-warm/5 border border-amber-400/20 dark:border-amber-400/10">
                  <step.icon className="h-10 w-10 text-amber-600 dark:text-amber-400" />
                </div>
                <span className="absolute -top-2 -right-2 flex h-7 w-7 items-center justify-center rounded-full bg-amber-500 text-xs font-bold text-white shadow-lg shadow-amber-500/30">
                  {step.number.replace("0", "")}
                </span>
              </div>

              <h3 className="mt-6 text-xl font-semibold text-stone-900 dark:text-stone-50">
                {step.title}
              </h3>
              <p className="mt-3 text-sm leading-relaxed text-stone-500 dark:text-stone-400 max-w-xs mx-auto">
                {step.description}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
