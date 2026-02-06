"use client";

import { useState, useRef } from "react";
import { motion, useInView, AnimatePresence } from "framer-motion";
import { ChevronDown } from "lucide-react";
import SectionHeading from "@/components/ui/SectionHeading";
import { FAQS, SITE } from "@/lib/constants";

function FAQItem({
  question,
  answer,
  isOpen,
  toggle,
}: {
  question: string;
  answer: string;
  isOpen: boolean;
  toggle: () => void;
}) {
  return (
    <div className="border-b border-stone-200/60 dark:border-white/[0.06]">
      <button
        onClick={toggle}
        className="flex w-full items-center justify-between py-5 text-left group"
        aria-expanded={isOpen}
      >
        <span className="text-base font-medium text-stone-900 dark:text-stone-50 pr-6 group-hover:text-amber-600 dark:group-hover:text-amber-400 transition-colors">
          {question}
        </span>
        <ChevronDown
          className={`h-5 w-5 shrink-0 text-stone-400 transition-transform duration-200 ${
            isOpen ? "rotate-180" : ""
          }`}
        />
      </button>
      <AnimatePresence initial={false}>
        {isOpen && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
            className="overflow-hidden"
          >
            <p className="pb-5 text-sm leading-relaxed text-stone-500 dark:text-stone-400 pr-10">
              {answer}
            </p>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

export default function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  const faqJsonLd = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: FAQS.map((faq) => ({
      "@type": "Question",
      name: faq.question,
      acceptedAnswer: {
        "@type": "Answer",
        text: faq.answer,
      },
    })),
  };

  return (
    <section id="faq" className="py-24 sm:py-32">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }}
      />

      <div className="mx-auto max-w-3xl px-6 lg:px-8">
        <SectionHeading
          eyebrow="FAQ"
          title="Frequently asked questions"
          description="Can't find what you're looking for? Reach out to our support team."
        />

        <motion.div
          ref={ref}
          initial={{ opacity: 0, y: 24 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
          className="mt-12"
        >
          {FAQS.map((faq, index) => (
            <FAQItem
              key={index}
              question={faq.question}
              answer={faq.answer}
              isOpen={openIndex === index}
              toggle={() =>
                setOpenIndex(openIndex === index ? null : index)
              }
            />
          ))}
        </motion.div>

        <p className="mt-10 text-center text-sm text-stone-500 dark:text-stone-400">
          Still have questions?{" "}
          <a
            href={`mailto:${SITE.supportEmail}`}
            className="font-medium text-amber-600 dark:text-amber-400 hover:underline underline-offset-2"
          >
            Contact us
          </a>
        </p>
      </div>
    </section>
  );
}
