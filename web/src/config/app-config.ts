import packageJson from "../../package.json";

const currentYear = new Date().getFullYear();

/**
 * 品牌配置（单一事实来源）。
 * 改这里即可全站换名：侧边栏、页面标题、登录页、关于页、导出物标题等。
 */
export const APP_CONFIG = {
  /** 产品名 */
  name: "Lucky",
  /** 登录账号名（服务端校验用，改动需同步 server/brand.go） */
  authUsername: "Lucky",
  /** 开发商/公司名 */
  company: "any",
  /** 产品线名（用于 About、导出报告页眉） */
  productLine: "Lucky Security Platform",
  /** 官网/支持地址，留空则不展示 */
  homepage: "",
  /** 支持邮箱，留空则不展示 */
  supportEmail: "",
  version: packageJson.version,
  copyright: `© ${currentYear}, ${"any"}. All rights reserved.`,
  /** 上游开源归属（AGPL-3.0 要求保留的署名） */
  attribution: "Based on ARTEX (AGPL-3.0)",
  meta: {
    title: "Lucky — 自主渗透测试控制台",
    description: "由 any 出品的 LLM 多智能体自主渗透测试平台",
    applicationName: "Lucky",
  },
  theme: {
    /** 品牌主色（与 styles/presets/lucky.css 保持一致） */
    primary: "#171717",
    radius: "0.5rem",
  },
};