"use client";

import { motion, type HTMLMotionProps } from "framer-motion";
import { type ReactNode } from "react";

interface GlassCardProps extends Omit<HTMLMotionProps<"div">, "children"> {
  children: ReactNode;
  variant?: "standard" | "elevated" | "subtle";
  hover?: boolean;
  className?: string;
}

export default function GlassCard({
  children,
  variant = "standard",
  hover = false,
  className = "",
  ...props
}: GlassCardProps) {
  const base =
    "rounded-2xl border backdrop-blur-xl transition-all duration-300";

  const variants = {
    standard:
      "bg-white/60 dark:bg-white/[0.04] border-white/80 dark:border-white/[0.08] shadow-sm",
    elevated:
      "bg-white/70 dark:bg-white/[0.06] border-white/90 dark:border-white/10 shadow-lg shadow-amber-500/[0.04] dark:shadow-amber-400/[0.02]",
    subtle:
      "bg-white/40 dark:bg-white/[0.02] border-white/60 dark:border-white/[0.06] shadow-none",
  };

  const hoverStyle = hover
    ? "hover:shadow-xl hover:shadow-amber-500/[0.08] dark:hover:shadow-amber-400/[0.04] hover:border-amber-400/30 dark:hover:border-amber-400/20 hover:-translate-y-0.5"
    : "";

  return (
    <motion.div
      className={`${base} ${variants[variant]} ${hoverStyle} ${className}`}
      {...props}
    >
      {children}
    </motion.div>
  );
}
