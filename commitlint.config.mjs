// Dependabot пишет тему с заглавной «Bump» и менять это нельзя: в commit-message
// у него есть только prefix и include. Такие коммиты пропускаются целиком, а
// defaultIgnores остаются включёнными, потому что ignores только дополняют их.
const dependabotHeader = /^build\(deps(-dev)?\): Bump /;

export default {
  extends: ["@commitlint/config-conventional"],
  ignores: [(message) => dependabotHeader.test(message)],
};
