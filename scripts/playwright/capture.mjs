/**
 * capture.mjs — Automated frontend screenshot capture using Playwright.
 *
 * Template-level tool: extracts routes from a generated project's frontend
 * source, authenticates if needed, and captures full-page screenshots.
 *
 * Usage:
 *   node capture.mjs --project-dir /abs/path/to/generated/project [--base-url http://localhost] [--force]
 */

import { chromium } from "playwright";
import { parse } from "@babel/parser";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = { baseUrl: "http://localhost", force: false, projectDir: "" };
  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case "--project-dir":
        opts.projectDir = args[++i];
        break;
      case "--base-url":
        opts.baseUrl = args[++i];
        break;
      case "--force":
        opts.force = true;
        break;
    }
  }
  if (!opts.projectDir) {
    console.error("Usage: node capture.mjs --project-dir <path> [--base-url URL] [--force]");
    process.exit(1);
  }
  // Remove trailing slash
  opts.baseUrl = opts.baseUrl.replace(/\/+$/, "");
  return opts;
}

// ---------------------------------------------------------------------------
// Phase 1: Route extraction
// ---------------------------------------------------------------------------

/** Recursively find files matching a predicate under a directory. */
function findFiles(dir, predicate, result = []) {
  if (!fs.existsSync(dir)) return result;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory() && entry.name !== "node_modules" && entry.name !== "dist") {
      findFiles(full, predicate, result);
    } else if (entry.isFile() && predicate(entry.name)) {
      result.push(full);
    }
  }
  return result;
}

/** Check if a source file likely contains React Router route definitions. */
function fileContainsRoutes(content) {
  return /\bRoute\b/.test(content) || /createBrowserRouter/.test(content) || /createRoutesFromElements/.test(content);
}

/**
 * Extract route paths from JSX/TSX source using @babel/parser.
 * Returns array of { path, protected } objects.
 */
function extractRoutesFromAST(source, filePath) {
  const routes = [];
  try {
    const ast = parse(source, {
      sourceType: "module",
      plugins: ["jsx", "typescript", "decorators-legacy"],
      errorRecovery: true,
    });
    walkAST(ast.program, routes, false);
  } catch (err) {
    console.warn(`  [warn] AST parse failed for ${filePath}: ${err.message}`);
    // Fallback: regex extraction
    extractRoutesRegex(source, routes);
  }
  return routes;
}

/** Walk AST nodes recursively to find Route-like JSX elements. */
function walkAST(node, routes, insideProtected) {
  if (!node || typeof node !== "object") return;

  // Handle JSX elements: <Route path="..." /> or <ProtectedRoute>
  if (node.type === "JSXElement" || node.type === "JSXFragment") {
    const opening = node.openingElement;
    if (opening && opening.name) {
      const tagName = jsxElementName(opening.name);

      // Check if this is a ProtectedRoute wrapper
      const isProtectedWrapper =
        tagName === "ProtectedRoute" ||
        tagName === "RequireAuth" ||
        tagName === "AuthGuard" ||
        tagName === "PrivateRoute";

      if (tagName === "Route") {
        const pathAttr = getJSXAttr(opening, "path");
        if (pathAttr && pathAttr !== "*") {
          routes.push({ path: pathAttr, protected: insideProtected });
        }
      }

      // Recurse into children with updated protection context
      if (node.children) {
        for (const child of node.children) {
          walkAST(child, routes, insideProtected || isProtectedWrapper);
        }
      }
      return; // children already processed
    }
  }

  // Handle createBrowserRouter / route config objects: { path: "..." }
  if (node.type === "ObjectExpression" && node.properties) {
    const pathProp = node.properties.find(
      (p) =>
        p.type === "ObjectProperty" &&
        ((p.key.type === "Identifier" && p.key.name === "path") ||
          (p.key.type === "StringLiteral" && p.key.value === "path"))
    );
    if (pathProp && pathProp.value.type === "StringLiteral") {
      const routePath = pathProp.value.value;
      if (routePath && routePath !== "*") {
        // Check if there's an element property referencing protected component
        const elementProp = node.properties.find(
          (p) => p.type === "ObjectProperty" && p.key.type === "Identifier" && p.key.name === "element"
        );
        let isProtected = insideProtected;
        if (elementProp) {
          const src = safeSourceFragment(elementProp);
          if (/ProtectedRoute|RequireAuth|AuthGuard|PrivateRoute/.test(src)) {
            isProtected = true;
          }
        }
        routes.push({ path: routePath, protected: isProtected });
      }
    }
  }

  // Recurse into all node properties
  for (const key of Object.keys(node)) {
    if (key === "leadingComments" || key === "trailingComments" || key === "innerComments") continue;
    const val = node[key];
    if (Array.isArray(val)) {
      for (const item of val) {
        if (item && typeof item === "object" && item.type) {
          walkAST(item, routes, insideProtected);
        }
      }
    } else if (val && typeof val === "object" && val.type) {
      walkAST(val, routes, insideProtected);
    }
  }
}

/** Get JSX element name as string. */
function jsxElementName(nameNode) {
  if (nameNode.type === "JSXIdentifier") return nameNode.name;
  if (nameNode.type === "JSXMemberExpression") {
    return jsxElementName(nameNode.object) + "." + jsxElementName(nameNode.property);
  }
  return "";
}

/** Get a JSX attribute value by name. */
function getJSXAttr(opening, attrName) {
  if (!opening.attributes) return null;
  for (const attr of opening.attributes) {
    if (attr.type === "JSXAttribute" && attr.name && attr.name.name === attrName) {
      if (attr.value) {
        if (attr.value.type === "StringLiteral") return attr.value.value;
        // {"/path"} expression
        if (attr.value.type === "JSXExpressionContainer" && attr.value.expression.type === "StringLiteral") {
          return attr.value.expression.value;
        }
      }
    }
  }
  return null;
}

/** Safely extract a rough source fragment for heuristic checks. */
function safeSourceFragment(node) {
  try {
    return JSON.stringify(node).slice(0, 500);
  } catch {
    return "";
  }
}

/** Regex fallback for route extraction when AST fails. */
function extractRoutesRegex(source, routes) {
  // Match <Route path="/xxx" or path: "/xxx"
  const patterns = [
    /path\s*[=:]\s*["']([^"'*]+)["']/g,
  ];
  const seen = new Set();
  for (const re of patterns) {
    let m;
    while ((m = re.exec(source)) !== null) {
      const p = m[1];
      if (!seen.has(p) && p.startsWith("/")) {
        seen.add(p);
        // Heuristic: check if ProtectedRoute appears near this match
        const context = source.slice(Math.max(0, m.index - 200), m.index + 200);
        const isProtected = /ProtectedRoute|RequireAuth|AuthGuard|PrivateRoute/.test(context);
        routes.push({ path: p, protected: isProtected });
      }
    }
  }
}

/** Fallback: derive routes from pages/ directory structure. */
function extractRoutesFromPages(frontendSrc) {
  const pagesDir = path.join(frontendSrc, "pages");
  if (!fs.existsSync(pagesDir)) return [];

  const routes = [];
  for (const entry of fs.readdirSync(pagesDir, { withFileTypes: true })) {
    if (!entry.isFile()) continue;
    const name = entry.name.replace(/\.(tsx?|jsx?)$/, "");
    if (!name || name.startsWith("_") || name === "index") continue;

    // Convert PascalCase/camelCase to kebab-case path
    const slug = name
      .replace(/([a-z])([A-Z])/g, "$1-$2")
      .toLowerCase();

    // Heuristic: admin/dashboard/workspace likely protected
    const isProtected = /admin|dashboard|workspace|profile|settings/i.test(name);
    routes.push({ path: `/${slug}`, protected: isProtected });
  }

  // Always add root
  if (fs.existsSync(path.join(pagesDir, "index.tsx")) || fs.existsSync(path.join(pagesDir, "Home.tsx"))) {
    routes.unshift({ path: "/", protected: false });
  }
  return routes;
}

/** Main route extraction entry point. */
function discoverRoutes(projectDir) {
  const frontendSrc = path.join(projectDir, "frontend", "src");
  if (!fs.existsSync(frontendSrc)) {
    console.warn("  [warn] frontend/src/ not found, cannot extract routes");
    return [];
  }

  // Find files that likely contain route definitions
  const candidates = findFiles(frontendSrc, (name) =>
    /\.(tsx?|jsx?)$/.test(name) && !/\.(test|spec|stories)\./i.test(name)
  );

  let allRoutes = [];
  for (const filePath of candidates) {
    const content = fs.readFileSync(filePath, "utf-8");
    if (!fileContainsRoutes(content)) continue;
    console.log(`  [info] Extracting routes from ${path.relative(projectDir, filePath)}`);
    const routes = extractRoutesFromAST(content, filePath);
    allRoutes.push(...routes);
  }

  // Deduplicate by path
  const seen = new Set();
  allRoutes = allRoutes.filter((r) => {
    if (seen.has(r.path)) return false;
    seen.add(r.path);
    return true;
  });

  // Fallback to pages/ directory scan
  if (allRoutes.length === 0) {
    console.log("  [info] No routes found via AST, falling back to pages/ directory scan");
    allRoutes = extractRoutesFromPages(frontendSrc);
  }

  if (allRoutes.length === 0) {
    console.warn("  [warn] No routes discovered. Will capture only root page.");
    allRoutes = [{ path: "/", protected: false }];
  }

  return allRoutes;
}

// ---------------------------------------------------------------------------
// Phase 2: Authentication
// ---------------------------------------------------------------------------

const TEST_USER = {
  email: "screenshot-bot@test.local",
  username: "screenshot_bot",
  password: "ScreenshotBot123!",
};

/** Detect whether the frontend uses cookie-based or localStorage auth. */
function detectAuthMode(projectDir) {
  const frontendSrc = path.join(projectDir, "frontend", "src");
  const files = findFiles(frontendSrc, (name) => /\.(tsx?|jsx?)$/.test(name));
  for (const f of files) {
    const content = fs.readFileSync(f, "utf-8");
    if (/httpOnly|withCredentials\s*:\s*true|credentials\s*:\s*['"]include['"]/.test(content)) {
      return "cookie";
    }
  }
  return "bearer";
}

/**
 * Attempt API-based authentication. Returns { token, mode } or null.
 * Tries multiple endpoint patterns for compatibility.
 */
async function authenticate(baseUrl) {
  const registerEndpoints = [
    "/api/v1/auth/register",
    "/api/v1/register",
    "/api/v1/users/register",
  ];
  const loginEndpoints = [
    "/api/v1/auth/login",
    "/api/v1/login",
    "/api/v1/auth/token",
    "/api/v1/users/login",
  ];

  // Try registration (may fail if user exists — that's OK)
  for (const ep of registerEndpoints) {
    try {
      const res = await fetch(`${baseUrl}${ep}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(TEST_USER),
      });
      if (res.ok || res.status === 409 || res.status === 422) {
        console.log(`  [info] Registration attempt via ${ep}: ${res.status}`);
        break;
      }
    } catch {
      // endpoint doesn't exist, try next
    }
  }

  // Try login
  for (const ep of loginEndpoints) {
    try {
      // Try JSON body
      let res = await fetch(`${baseUrl}${ep}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: TEST_USER.email,
          username: TEST_USER.username,
          password: TEST_USER.password,
        }),
      });

      // Some APIs use form-encoded for OAuth2 token endpoint
      if (!res.ok && res.status !== 401) {
        const formBody = new URLSearchParams({
          username: TEST_USER.email,
          password: TEST_USER.password,
        });
        res = await fetch(`${baseUrl}${ep}`, {
          method: "POST",
          headers: { "Content-Type": "application/x-www-form-urlencoded" },
          body: formBody.toString(),
        });
      }

      if (res.ok) {
        const data = await res.json().catch(() => null);
        const token =
          data?.access_token ||
          data?.token ||
          data?.data?.access_token ||
          data?.data?.token;

        // Check for Set-Cookie header
        const cookies = res.headers.getSetCookie?.() || [];
        const hasCookieAuth = cookies.some((c) => /access_token|session/i.test(c));

        if (token) {
          console.log(`  [info] Login succeeded via ${ep} (bearer token)`);
          return { token, mode: "bearer", cookies: [] };
        }
        if (hasCookieAuth) {
          console.log(`  [info] Login succeeded via ${ep} (cookie)`);
          return { token: null, mode: "cookie", cookies };
        }
        // Might be OK without explicit token (session-based)
        console.log(`  [info] Login response OK from ${ep} but no token/cookie found`);
        return { token: null, mode: "unknown", cookies };
      }
    } catch {
      // endpoint doesn't exist, try next
    }
  }

  console.warn("  [warn] Authentication failed — will only capture public pages");
  return null;
}

// ---------------------------------------------------------------------------
// Phase 3: Screenshot capture
// ---------------------------------------------------------------------------

/** Determine sort priority for a route path (lower = first). */
function routeSortKey(routePath) {
  // Public/auth pages first
  const priorities = {
    "/login": 0,
    "/register": 1,
    "/": 2,
    "/home": 3,
  };
  if (routePath in priorities) return priorities[routePath];

  // Dashboard/workspace next
  if (/dashboard|workspace|home/i.test(routePath)) return 10;

  // List pages
  if (!/:\w+/.test(routePath)) return 20;

  // Detail/dynamic pages last
  return 30;
}

/** Convert route path to a human-friendly screenshot filename. */
function routeToFilename(routePath, index) {
  const num = String(index + 1).padStart(2, "0");
  if (routePath === "/") return `${num}-home.png`;

  const name = routePath
    .replace(/^\//, "")
    .replace(/\/:\w+/g, "-detail")
    .replace(/\//g, "-")
    .replace(/[^a-zA-Z0-9-]/g, "")
    .toLowerCase();

  return `${num}-${name || "page"}.png`;
}

/**
 * For dynamic routes like /skills/:id, try to fetch a real entity ID
 * from the corresponding list API endpoint.
 */
async function resolveDynamicParam(routePath, baseUrl, authToken) {
  // Extract the resource name from the path prefix before the param
  // e.g. /skills/:id -> skills, /admin/users/:userId -> users
  const segments = routePath.split("/").filter(Boolean);
  const paramIdx = segments.findIndex((s) => s.startsWith(":"));
  if (paramIdx <= 0) return null;

  const resource = segments[paramIdx - 1];
  const apiPath = `/api/v1/${resource}?page=1&page_size=1`;

  try {
    const headers = {};
    if (authToken) headers["Authorization"] = `Bearer ${authToken}`;

    const res = await fetch(`${baseUrl}${apiPath}`, { headers });
    if (!res.ok) return null;

    const data = await res.json();
    // Handle both { data: { items: [...] } } and { items: [...] } and [...]
    const items = data?.data?.items || data?.items || (Array.isArray(data?.data) ? data.data : null) || (Array.isArray(data) ? data : null);
    if (items && items.length > 0) {
      const item = items[0];
      return item.id || item.slug || item.uuid || null;
    }
  } catch {
    // API not available
  }
  return null;
}

/** Replace dynamic params in a route path with resolved values. */
function resolveRoutePath(routePath, resolvedId) {
  if (!resolvedId) return null;
  return routePath.replace(/:\w+/, String(resolvedId));
}

/** Capture a single page screenshot. */
async function captureScreenshot(page, url, outputPath, timeoutMs = 30000) {
  try {
    await page.goto(url, { waitUntil: "networkidle", timeout: timeoutMs });
    // Extra wait for rendering stability (animations, lazy content)
    await page.waitForTimeout(800);
    await page.screenshot({ path: outputPath, fullPage: true });
    return true;
  } catch (err) {
    console.warn(`  [warn] Failed to capture ${url}: ${err.message}`);
    return false;
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const opts = parseArgs();
  const { projectDir, baseUrl, force } = opts;

  const screenshotDir = path.join(projectDir, "doc", "screenshots");

  // Check if screenshots already exist
  if (!force && fs.existsSync(screenshotDir)) {
    const existing = fs.readdirSync(screenshotDir).filter((f) => /\.(png|jpe?g|gif|webp)$/i.test(f));
    if (existing.length >= 3) {
      console.log(`Screenshots already present (${existing.length} files). Use --force to overwrite.`);
      process.exit(0);
    }
  }

  console.log("=== Phase 1: Route Discovery ===");
  let routes = discoverRoutes(projectDir);

  // Sort routes: public pages first, then by path
  routes.sort((a, b) => {
    const ka = routeSortKey(a.path);
    const kb = routeSortKey(b.path);
    if (ka !== kb) return ka - kb;
    return a.path.localeCompare(b.path);
  });

  console.log(`  Found ${routes.length} route(s):`);
  for (const r of routes) {
    console.log(`    ${r.path}${r.protected ? " [protected]" : ""}`);
  }

  console.log("\n=== Phase 2: Authentication ===");
  const authMode = detectAuthMode(projectDir);
  console.log(`  Detected auth mode: ${authMode}`);

  const hasProtectedRoutes = routes.some((r) => r.protected);
  let authResult = null;
  if (hasProtectedRoutes) {
    authResult = await authenticate(baseUrl);
  } else {
    console.log("  No protected routes detected, skipping authentication.");
  }

  console.log("\n=== Phase 3: Screenshot Capture ===");

  // Ensure output directory exists
  fs.mkdirSync(screenshotDir, { recursive: true });

  // Clear existing screenshots if --force
  if (force && fs.existsSync(screenshotDir)) {
    for (const f of fs.readdirSync(screenshotDir)) {
      if (/\.(png|jpe?g|gif|webp)$/i.test(f)) {
        fs.unlinkSync(path.join(screenshotDir, f));
      }
    }
  }

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 800 },
    locale: "zh-CN",
  });

  // Set up authentication in browser context
  if (authResult) {
    if (authResult.mode === "bearer" && authResult.token) {
      // Inject token into localStorage before navigating
      const page = await context.newPage();
      await page.goto(baseUrl, { waitUntil: "domcontentloaded", timeout: 15000 });
      await page.evaluate((token) => {
        localStorage.setItem("access_token", token);
        localStorage.setItem("token", token);
      }, authResult.token);
      await page.close();
    }
    // For cookie mode, we need to make the login request through the browser
    if (authResult.mode === "cookie") {
      const page = await context.newPage();
      // Navigate first to set the domain
      await page.goto(baseUrl, { waitUntil: "domcontentloaded", timeout: 15000 });
      // Make login request from browser context to get cookies set
      await page.evaluate(
        async ({ baseUrl, user }) => {
          const endpoints = ["/api/v1/auth/login", "/api/v1/login"];
          for (const ep of endpoints) {
            try {
              const res = await fetch(`${baseUrl}${ep}`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                credentials: "include",
                body: JSON.stringify({
                  email: user.email,
                  username: user.username,
                  password: user.password,
                }),
              });
              if (res.ok) break;
            } catch {}
          }
        },
        { baseUrl, user: TEST_USER }
      );
      await page.close();
    }
  }

  const page = await context.newPage();
  let capturedCount = 0;
  let screenshotIndex = 0;

  for (const route of routes) {
    let targetPath = route.path;

    // Skip protected routes if auth failed
    if (route.protected && !authResult) {
      console.log(`  [skip] ${route.path} (protected, no auth)`);
      continue;
    }

    // Resolve dynamic parameters
    if (/:\w+/.test(targetPath)) {
      const entityId = await resolveDynamicParam(targetPath, baseUrl, authResult?.token);
      if (entityId) {
        targetPath = resolveRoutePath(targetPath, entityId);
        console.log(`  [info] Resolved ${route.path} → ${targetPath}`);
      } else {
        console.log(`  [skip] ${route.path} (no data for dynamic param)`);
        continue;
      }
    }

    const url = `${baseUrl}${targetPath}`;
    const filename = routeToFilename(route.path, screenshotIndex);
    const outputPath = path.join(screenshotDir, filename);

    console.log(`  Capturing ${url} → ${filename}`);
    const ok = await captureScreenshot(page, url, outputPath);
    if (ok) {
      capturedCount++;
      screenshotIndex++;
    }
  }

  await browser.close();

  console.log(`\n=== Done ===`);
  console.log(`Captured ${capturedCount} screenshot(s) in ${screenshotDir}`);

  if (capturedCount < 3) {
    console.warn(`[warn] Only ${capturedCount} screenshots captured (minimum 3 expected)`);
    process.exit(1);
  }

  process.exit(0);
}

main().catch((err) => {
  console.error("Screenshot capture failed:", err);
  process.exit(1);
});
