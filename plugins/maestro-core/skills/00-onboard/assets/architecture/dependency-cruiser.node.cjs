/** Maestro architecture boundaries — written by maestro-core:00-onboard scaffold,
 *  enforced by `maestro-check boundaries` (dependency-cruiser). Edit freely:
 *  the rule that matters is the first one. Layers:
 *    domain/         entities, value objects, domain services — pure, no framework
 *    application/    use cases, ports (interfaces) — depends on domain only
 *    infrastructure/ adapters: Prisma, Firebase, HTTP, Expo APIs, Clerk…
 *    ui/ | app/ | components/   screens and components — may use application, never infrastructure directly
 *  Paths are matched anywhere under src/, app/, lib/ (monorepo packages included). */
module.exports = {
  forbidden: [
    {
      name: 'domain-stays-pure',
      severity: 'error',
      comment: 'domain/ imports nothing from application/, infrastructure/ or the UI, and no framework package.',
      from: { path: '(^|/)domain/' },
      to: { path: '(^|/)(application|infrastructure|ui|app|components|screens)/' },
    },
    {
      name: 'domain-no-framework',
      severity: 'error',
      comment: 'domain/ does not import a framework or an adapter package (Prisma, Firebase, React, Expo, Next, Clerk, axios…). Pure libraries are allowed on purpose — zod/valibot as value-object schemas, date-fns, decimal.js: no I/O, no runtime of their own. Add a package here the day it starts doing I/O.',
      from: { path: '(^|/)domain/' },
      to: { path: 'node_modules/(@prisma|prisma|firebase|@firebase|@react-native-firebase|react|react-dom|react-native|expo|@expo|next|@clerk|axios|@tanstack|zustand|@supabase|@stripe|stripe)/' },
    },
    {
      name: 'application-no-infrastructure',
      severity: 'error',
      comment: 'application/ talks to ports (interfaces in application/ or domain/), never to infrastructure/ adapters directly — the wiring lives at the edge (app/, infrastructure/di).',
      from: { path: '(^|/)application/' },
      to: { path: '(^|/)infrastructure/' },
    },
    {
      name: 'ui-no-infrastructure',
      severity: 'error',
      comment: 'Screens and components — including Expo Router / Next app/ routes — call use cases (application/), not Prisma/Firebase/HTTP adapters. The one place that may import infrastructure to wire ports is the composition edge: composition/, di/, providers/, or a root layout (app/_layout.tsx, app/layout.tsx).',
      // features/ is feature-sliced: only its UI-ish folders count as UI; infrastructure/application/domain inside a feature are those layers
      from: { path: '(^|/)(ui|components|screens|app|features|pages)/', pathNot: '(^|/)(composition|di|providers|infrastructure|application|domain)/|(^|/)app/(_layout|layout|providers)\\.[jt]sx?$' },
      to: { path: '(^|/)infrastructure/' },
    },
    { name: 'no-circular', severity: 'error', from: {}, to: { circular: true } },
    { name: 'no-orphans', severity: 'warn', from: { orphan: true, pathNot: ['\\.d\\.ts$', '(^|/)index\\.[jt]sx?$', '\\.(test|spec|stories)\\.'] }, to: {} },
  ],
  options: {
    doNotFollow: { path: 'node_modules' },
    // node_modules is followed one hop (so a framework import resolves to a path the rules can name), never deeper
    exclude: { path: '(^|/)(\\.expo|\\.next|dist|build|coverage|android|ios)/' },
    tsPreCompilationDeps: true,
    tsConfig: { fileName: 'tsconfig.json' },
    enhancedResolveOptions: { exportsFields: ['exports'], conditionNames: ['import', 'require', 'node', 'default', 'react-native'] },
    reporterOptions: { text: { highlightFocused: true } },
  },
};
