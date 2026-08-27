import js from "@eslint/js";
import pluginVue from "eslint-plugin-vue";
import tseslint from "typescript-eslint";
import globals from "globals";

export default tseslint.config(
  { ignores: [".nuxt", ".output", "dist", "e2e"] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  ...pluginVue.configs["flat/recommended"],
  {
    files: ["**/*.{ts,vue}"],
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
        $fetch: "readonly",
        computed: "readonly",
        onMounted: "readonly",
        ref: "readonly",
        useI18n: "readonly",
        useRoute: "readonly",
        useRouter: "readonly",
        useSession: "readonly",
      },
      parserOptions: { parser: tseslint.parser },
    },
    rules: { "vue/multi-word-component-names": "off" },
  },
);
