"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";
import {
  Globe,
  Mic,
  MessageSquare,
  Bookmark,
  WifiOff,
  Zap,
} from "lucide-react";
import GlassCard from "@/components/ui/GlassCard";
import SectionHeading from "@/components/ui/SectionHeading";
import { FEATURES } from "@/lib/constants";

const ICON_MAP = {
  Globe,
  Mic,
  MessageSquare,
  Bookmark,
  WifiOff,
  Zap,
} as const;

export default function Features() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section id="features" className="py-24 sm:py-32 relative">
      {/* Subtle background accent */}
      <div className="absolute inset-0 -z-10" aria-hidden="true">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 h-[600px] w-[800px] rounded-full bg-amber-400/[0.04] dark:bg-amber-400/[0.02] blur-[120px]" />
      </div>

      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <SectionHeading
          eyebrow="Features"
          title="Everything you need to communicate globally"
          description="Verbio combines cutting-edge AI with a beautifully simple interface to make cross-language communication effortless."
        />

        <div
          ref={ref}
          className="mt-16 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3"
        >
          {FEATURES.map((feature, index) => {
            const Icon = ICON_MAP[feature.icon];
            return (
              <motion.div
                key={feature.title}
                initial={{ opacity: 0, y: 32 }}
                animate={inView ? { opacity: 1, y: 0 } : {}}
                transition={{
                  duration: 0.5,
                  delay: index * 0.08,
                  ease: [0.22, 1, 0.36, 1],
                }}
              >
                <GlassCard hover variant="standard" className="p-6 h-full">
                  <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-gradient-to-br from-amber-400/20 to-orange-warm/10 dark:from-amber-400/10 dark:to-orange-warm/5 mb-4">
                    <Icon className="h-5 w-5 text-amber-600 dark:text-amber-400" />
                  </div>
                  <h3 className="text-lg font-semibold text-stone-900 dark:text-stone-50 mb-2">
                    {feature.title}
                  </h3>
                  <p className="text-sm leading-relaxed text-stone-500 dark:text-stone-400">
                    {feature.description}
                  </p>
                </GlassCard>
              </motion.div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
