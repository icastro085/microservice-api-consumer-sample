/*
 * For a detailed explanation regarding each configuration property and type check, visit:
 * https://jestjs.io/docs/configuration
 */
export default {
  clearMocks: true,
  collectCoverage: true,
  collectCoverageFrom: ["<rootDir>/src/**/*.ts"],
  coverageDirectory: "__coverage__",
  coverageProvider: "v8",
  coverageReporters: ["lcov", "text-summary"],
  preset: "ts-jest",
  testMatch: ["**/__tests__/**/*.[jt]s?(x)"],
  moduleNameMapper: {
    "@/(.*)": "<rootDir>/src/$1",
  },
  modulePathIgnorePatterns: ["build"],
};
