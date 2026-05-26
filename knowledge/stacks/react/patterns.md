# React Patterns Knowledge Base

## Propósito
Conocimiento experto de React que se inyecta en agents durante /genesis.
Se usa cuando el proyecto incluye React en su stack.

---

## Reglas de Hooks

### Las 2 reglas fundamentales
```typescript
// 1. Solo llamar hooks en el top level
// MAL
if (condition) {
  const [state, setState] = useState();  // ❌
}

// BIEN
const [state, setState] = useState();
if (condition) {
  // usar state aquí
}

// 2. Solo llamar hooks desde componentes o custom hooks
// MAL
function regularFunction() {
  const [state, setState] = useState();  // ❌
}

// BIEN
function useCustomHook() {
  const [state, setState] = useState();  // ✓
}
```

### Order matters
```typescript
// React depende del ORDEN de llamadas de hooks
// Si el orden cambia entre renders, bugs sutiles

function Component({ showExtra }) {
  const [name, setName] = useState('');

  // MAL: hook condicional cambia el orden
  if (showExtra) {
    const [extra, setExtra] = useState('');  // ❌
  }

  const [age, setAge] = useState(0);
}
```

---

## useState Patterns

### State inicial computado
```typescript
// MAL: Se ejecuta en CADA render
const [items, setItems] = useState(expensiveComputation(props));

// BIEN: Lazy initialization, solo en mount
const [items, setItems] = useState(() => expensiveComputation(props));
```

### State de objetos
```typescript
// MAL: Mutación directa
const [user, setUser] = useState({ name: '', age: 0 });
user.name = 'John';  // ❌ No triggerea re-render

// BIEN: Nuevo objeto
setUser({ ...user, name: 'John' });

// MEJOR: Con updater function
setUser(prev => ({ ...prev, name: 'John' }));
```

### State derivado
```typescript
// MAL: State duplicado
const [items, setItems] = useState([]);
const [filteredItems, setFilteredItems] = useState([]);

useEffect(() => {
  setFilteredItems(items.filter(i => i.active));
}, [items]);

// BIEN: Calcular en render
const [items, setItems] = useState([]);
const filteredItems = items.filter(i => i.active);

// Si es costoso, useMemo
const filteredItems = useMemo(
  () => items.filter(i => i.active),
  [items]
);
```

---

## useEffect Patterns

### Cleanup
```typescript
useEffect(() => {
  const subscription = subscribe(id);

  // SIEMPRE cleanup para evitar memory leaks
  return () => {
    subscription.unsubscribe();
  };
}, [id]);
```

### Fetch data pattern
```typescript
useEffect(() => {
  let cancelled = false;

  async function fetchData() {
    const data = await fetch(`/api/users/${id}`);
    if (!cancelled) {
      setData(data);
    }
  }

  fetchData();

  // Cleanup evita actualizar state de componente unmounted
  return () => {
    cancelled = true;
  };
}, [id]);
```

### Evitar loops infinitos
```typescript
// MAL: Se ejecuta infinitamente
useEffect(() => {
  setCount(count + 1);  // Cambia state → re-render → effect → ...
});

// MAL: Objeto nuevo cada render
useEffect(() => {
  doSomething(options);
}, [{ limit: 10 }]);  // Nuevo objeto = nueva referencia cada vez

// BIEN: Dependencias estables
const options = useMemo(() => ({ limit: 10 }), []);
useEffect(() => {
  doSomething(options);
}, [options]);
```

### No effect para todo
```typescript
// MAL: Effect para transformar datos
useEffect(() => {
  setFullName(`${firstName} ${lastName}`);
}, [firstName, lastName]);

// BIEN: Calcular directamente
const fullName = `${firstName} ${lastName}`;
```

---

## useMemo y useCallback

### Cuándo usar useMemo
```typescript
// USAR cuando:
// 1. Cálculo costoso
const sortedItems = useMemo(
  () => items.sort((a, b) => a.name.localeCompare(b.name)),
  [items]
);

// 2. Referencia estable para dependencias
const config = useMemo(
  () => ({ theme, locale }),
  [theme, locale]
);

// NO USAR cuando:
// - Operaciones simples
const fullName = firstName + ' ' + lastName;  // No necesita memo
```

### Cuándo usar useCallback
```typescript
// USAR cuando:
// 1. Pasas función a componente memoizado
const handleClick = useCallback(() => {
  doSomething(id);
}, [id]);

<MemoizedChild onClick={handleClick} />

// 2. Función en array de dependencias
const handleSubmit = useCallback(() => {
  submit(formData);
}, [formData]);

useEffect(() => {
  form.onSubmit(handleSubmit);
}, [handleSubmit]);

// NO USAR cuando:
// - Componente hijo no está memoizado
// - La función no es dependencia de nada
```

### No premature optimization
```typescript
// Primero: código simple
const items = data.filter(d => d.active);

// Solo si hay problema de performance medido:
const items = useMemo(() => data.filter(d => d.active), [data]);
```

---

## Component Patterns

### Container/Presentational
```typescript
// Container: lógica y data
function UserListContainer() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUsers().then(setUsers).finally(() => setLoading(false));
  }, []);

  return <UserList users={users} loading={loading} />;
}

// Presentational: solo UI
function UserList({ users, loading }) {
  if (loading) return <Spinner />;
  return (
    <ul>
      {users.map(u => <UserItem key={u.id} user={u} />)}
    </ul>
  );
}
```

### Compound Components
```typescript
// API tipo <select>/<option>
function Tabs({ children }) {
  const [activeTab, setActiveTab] = useState(0);
  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      {children}
    </TabsContext.Provider>
  );
}

Tabs.Tab = function Tab({ index, children }) {
  const { activeTab, setActiveTab } = useContext(TabsContext);
  return (
    <button
      onClick={() => setActiveTab(index)}
      className={activeTab === index ? 'active' : ''}
    >
      {children}
    </button>
  );
};

// Uso
<Tabs>
  <Tabs.Tab index={0}>First</Tabs.Tab>
  <Tabs.Tab index={1}>Second</Tabs.Tab>
</Tabs>
```

### Render Props
```typescript
// Para compartir lógica con control sobre rendering
function MouseTracker({ render }) {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const handler = (e) => setPosition({ x: e.clientX, y: e.clientY });
    window.addEventListener('mousemove', handler);
    return () => window.removeEventListener('mousemove', handler);
  }, []);

  return render(position);
}

// Uso
<MouseTracker render={({ x, y }) => (
  <p>Mouse at {x}, {y}</p>
)} />
```

---

## State Management

### Cuándo usar qué
```
useState     → State local del componente
useReducer   → State complejo con múltiples acciones
Context      → State compartido por árbol de componentes
Zustand/Jotai → State global simple
Redux        → State global complejo con middleware
React Query  → Server state (cache, sync)
```

### useReducer para state complejo
```typescript
type State = { count: number; step: number };
type Action =
  | { type: 'increment' }
  | { type: 'decrement' }
  | { type: 'setStep'; step: number };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'increment':
      return { ...state, count: state.count + state.step };
    case 'decrement':
      return { ...state, count: state.count - state.step };
    case 'setStep':
      return { ...state, step: action.step };
    default:
      return state;
  }
}

function Counter() {
  const [state, dispatch] = useReducer(reducer, { count: 0, step: 1 });

  return (
    <>
      <p>{state.count}</p>
      <button onClick={() => dispatch({ type: 'increment' })}>+</button>
    </>
  );
}
```

### Context sin re-renders innecesarios
```typescript
// MAL: Todo re-render cuando cambia cualquier cosa
const AppContext = createContext({ user: null, theme: 'light', setTheme: () => {} });

// BIEN: Separar contextos
const UserContext = createContext(null);
const ThemeContext = createContext({ theme: 'light', setTheme: () => {} });

// MEJOR: Separar state de dispatch
const CountStateContext = createContext(0);
const CountDispatchContext = createContext(() => {});
```

---

## Performance Patterns

### React.memo
```typescript
// Memoizar componente que recibe props estables
const ExpensiveList = React.memo(function ExpensiveList({ items }) {
  return items.map(item => <ExpensiveItem key={item.id} item={item} />);
});

// Custom comparison
const UserCard = React.memo(
  function UserCard({ user }) { /* ... */ },
  (prevProps, nextProps) => prevProps.user.id === nextProps.user.id
);
```

### Lazy loading
```typescript
// Code splitting por ruta
const Dashboard = lazy(() => import('./Dashboard'));
const Settings = lazy(() => import('./Settings'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

### Virtualización para listas largas
```typescript
// Con react-window
import { FixedSizeList } from 'react-window';

function VirtualList({ items }) {
  return (
    <FixedSizeList
      height={400}
      width={300}
      itemCount={items.length}
      itemSize={35}
    >
      {({ index, style }) => (
        <div style={style}>{items[index].name}</div>
      )}
    </FixedSizeList>
  );
}
```

### Keys estables
```typescript
// MAL: Index como key si lista cambia
items.map((item, index) => <Item key={index} />);

// BIEN: ID único y estable
items.map(item => <Item key={item.id} />);

// Si no hay ID, generar uno al crear el item, no en render
const items = rawItems.map(i => ({ ...i, id: crypto.randomUUID() }));
```

---

## Error Handling

### Error Boundary
```typescript
class ErrorBoundary extends React.Component {
  state = { hasError: false, error: null };

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, info) {
    logErrorToService(error, info);
  }

  render() {
    if (this.state.hasError) {
      return <ErrorFallback error={this.state.error} />;
    }
    return this.props.children;
  }
}

// Uso
<ErrorBoundary>
  <FeatureComponent />
</ErrorBoundary>
```

### Async error handling
```typescript
function useAsync(asyncFn, deps) {
  const [state, setState] = useState({
    loading: false,
    error: null,
    data: null
  });

  useEffect(() => {
    setState(s => ({ ...s, loading: true }));

    asyncFn()
      .then(data => setState({ loading: false, error: null, data }))
      .catch(error => setState({ loading: false, error, data: null }));
  }, deps);

  return state;
}
```

---

## Testing Patterns

### Testing Library philosophy
```typescript
// Testear como usuario, no implementación

// MAL: Testear implementación
expect(component.state.isOpen).toBe(true);

// BIEN: Testear comportamiento
expect(screen.getByRole('dialog')).toBeVisible();
```

### Queries por prioridad
```typescript
// 1. Accesible a todos
screen.getByRole('button', { name: /submit/i });
screen.getByLabelText(/email/i);
screen.getByPlaceholderText(/search/i);
screen.getByText(/welcome/i);

// 2. Semantic queries
screen.getByAltText(/profile/i);
screen.getByTitle(/close/i);

// 3. Test IDs (último recurso)
screen.getByTestId('custom-element');
```

### User events
```typescript
import userEvent from '@testing-library/user-event';

test('submits form', async () => {
  const user = userEvent.setup();

  render(<LoginForm onSubmit={handleSubmit} />);

  await user.type(screen.getByLabelText(/email/i), 'test@test.com');
  await user.type(screen.getByLabelText(/password/i), 'password123');
  await user.click(screen.getByRole('button', { name: /submit/i }));

  expect(handleSubmit).toHaveBeenCalledWith({
    email: 'test@test.com',
    password: 'password123'
  });
});
```

---

## Common Pitfalls

### Stale closures
```typescript
// MAL: count siempre es 0
function Counter() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    const id = setInterval(() => {
      setCount(count + 1);  // count es closure del valor inicial
    }, 1000);
    return () => clearInterval(id);
  }, []);  // Dependencias vacías = closure stale
}

// BIEN: Usar updater function
setCount(c => c + 1);

// O incluir en dependencias
useEffect(() => {
  // ...
}, [count]);
```

### Props drilling
```typescript
// MAL: Pasar props por muchos niveles
<App user={user}>
  <Layout user={user}>
    <Header user={user}>
      <UserMenu user={user} />
    </Header>
  </Layout>
</App>

// BIEN: Context o composition
<UserContext.Provider value={user}>
  <Layout>
    <Header>
      <UserMenu />  {/* Consume context directamente */}
    </Header>
  </Layout>
</UserContext.Provider>
```

### Leaky useEffect
```typescript
// MAL: No cleanup
useEffect(() => {
  window.addEventListener('resize', handler);
  // Memory leak si componente se desmonta
});

// BIEN: Cleanup
useEffect(() => {
  window.addEventListener('resize', handler);
  return () => window.removeEventListener('resize', handler);
}, []);
```

---

## Checklist React

### Por componente
- [ ] Hooks en top level, orden consistente
- [ ] useEffect tiene cleanup si es necesario
- [ ] Keys estables en listas
- [ ] Error boundary si puede fallar
- [ ] Loading states manejados

### Performance
- [ ] React.memo solo donde hay beneficio medido
- [ ] useMemo/useCallback no prematuros
- [ ] Lazy loading de rutas
- [ ] Virtualización si lista >100 items

### Accesibilidad
- [ ] Semantic HTML (button, nav, main)
- [ ] Labels en inputs
- [ ] Alt en imágenes
- [ ] Keyboard navigation funciona
