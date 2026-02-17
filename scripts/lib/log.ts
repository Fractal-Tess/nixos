export const c = {
  red:    "\x1b[0;31m",
  green:  "\x1b[0;32m",
  yellow: "\x1b[1;33m",
  blue:   "\x1b[0;34m",
  purple: "\x1b[0;35m",
  cyan:   "\x1b[0;36m",
  bold:   "\x1b[1m",
  dim:    "\x1b[2m",
  reset:  "\x1b[0m",
};

export const log = {
  header:  (msg: string) => {
    console.log(`\n${c.purple}${c.bold}══════════════════════════════════════════════════════════════${c.reset}`);
    console.log(`${c.purple}${c.bold}  ${msg}${c.reset}`);
    console.log(`${c.purple}${c.bold}══════════════════════════════════════════════════════════════${c.reset}\n`);
  },
  info:    (msg: string) => console.log(`${c.blue}•${c.reset} ${msg}`),
  success: (msg: string) => console.log(`${c.green}✓${c.reset} ${msg}`),
  warning: (msg: string) => console.log(`${c.yellow}⚠${c.reset} ${msg}`),
  error:   (msg: string) => console.log(`${c.red}✗ ERROR:${c.reset} ${msg}`),
  step:    (msg: string) => console.log(`\n${c.cyan}→${c.reset} ${c.bold}${msg}${c.reset}`),
  dim:     (msg: string) => console.log(`${c.dim}${msg}${c.reset}`),
};
