"use client";

import type { ToolRendererProps } from "@/types/events";
import { TruncatedText } from "./ToolCard";

export default function FinishRenderer({ args }: ToolRendererProps) {
  const executiveSummary = (args.executive_summary as string) ?? "";
  const methodology = (args.methodology as string) ?? "";
  const technicalAnalysis = (args.technical_analysis as string) ?? "";
  const recommendations = (args.recommendations as string) ?? "";

  return (
    <div className="space-y-3">
      <span className="text-emerald-400/80 font-semibold text-sm">滲透測試完成</span>
      {executiveSummary && (
        <div><span className="text-emerald-400/60 text-sm font-semibold">執行摘要</span><div className="mt-1"><TruncatedText text={executiveSummary} maxLines={25} /></div></div>
      )}
      {methodology && (
        <div><span className="text-emerald-400/60 text-sm font-semibold">方法論</span><div className="mt-1"><TruncatedText text={methodology} maxLines={25} /></div></div>
      )}
      {technicalAnalysis && (
        <div><span className="text-emerald-400/60 text-sm font-semibold">技術分析</span><div className="mt-1"><TruncatedText text={technicalAnalysis} maxLines={25} /></div></div>
      )}
      {recommendations && (
        <div><span className="text-emerald-400/60 text-sm font-semibold">建議</span><div className="mt-1"><TruncatedText text={recommendations} maxLines={25} /></div></div>
      )}
      {!executiveSummary && !methodology && !technicalAnalysis && !recommendations && (
        <div className="text-[#555] text-xs">正在產生最終報告...</div>
      )}
    </div>
  );
}
