---
name: javascript
description: Vanilla JavaScript style conventions for browser UIs. Use when writing or reviewing JS — no transpiler, no framework, modern browsers only. Covers module pattern, style rules, async error handling, and form POST pattern.
---

## Module pattern

```js
let App = {};
let $ = sel => document.querySelector(sel);

App.doThing = function(event, id) { ... };

export default App;
```

```html
<script type="module">
  import App from './app.js';
  window.App = App;
  App.init();
</script>
<button onclick="App.doThing(event, this.dataset.id)" data-id="123">Click</button>
```

- Export a plain object (`App`), not a class
- `window.App = App` exposes it for inline `onclick` handlers
- Inline `onclick="App.method(event)"` — no `addEventListener` wiring
- `let $ = sel => document.querySelector(sel)` — no `getElementById`

## Style rules

- **No ternaries** — use `if/else`
- **No arrow functions** for named logic — use `function` declarations
- **No try/catch** unless adding classification; let errors propagate to the unhandled
  rejection handler
- **`for (let x of list)`** when the index isn't needed; no `.forEach()`
- **Explicit over clever** — name each thing, no destructuring tricks, no array-of-tuples iteration
- **`URLSearchParams.set()`** per param, not object shorthand
- **String concatenation** for simple strings, not template literals

## Async error handling

Set `currentEvent` at the top of each async handler so the global rejection handler
can route errors to the right place:

```js
let currentEvent = null;

App.submit = async function(event) {
    currentEvent = event;
    // ... no try/catch
};

// In App.init():
window.addEventListener('unhandledrejection', function(e) {
    let reason;
    if (e.reason instanceof Error) {
        reason = e.reason.message;
    } else {
        reason = String(e.reason);
    }
    if (currentEvent) {
        handleResult(currentEvent, reason, false);
    }
});
```

## Form POST for redirects

Build forms dynamically rather than hiding them in the markup:

```js
let form    = document.createElement('form');
form.method = 'POST';
form.action = '/some/endpoint';
document.body.appendChild(form);
addHidden(form, 'field_name', value);
form.submit();
```
