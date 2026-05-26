# React Best Practices

> Este archivo extiende las convenciones generales de `rules/code-style.md`.
> Las reglas de React se aplican además de las reglas generales de código.

## Aplica a
Archivos `.tsx`, `.jsx` y componentes React.

## Reglas de Componentes

### Estructura
- Un componente por archivo
- Nombre en PascalCase
- Props interface encima del componente
- Exportar como named export

### Props
- Interface con sufijo `Props`
- Documentar props complejas con JSDoc
- Destructurar en la firma de la funcion
- Usar valores por defecto en destructuring

### Ejemplo Correcto

```tsx
interface UserCardProps {
  /** User data to display */
  user: User;
  /** Called when card is clicked */
  onClick?: () => void;
}

export const UserCard: FC<UserCardProps> = ({
  user,
  onClick,
}) => {
  return (
    <article onClick={onClick}>
      <h2>{user.name}</h2>
    </article>
  );
};
```

## Reglas de Hooks

### Llamadas
- Solo en el nivel superior (no en condicionales, loops, callbacks)
- Solo en componentes funcionales o custom hooks
- Custom hooks empiezan con `use`

### Dependencias
- Incluir todas las dependencias en el array
- Usar funciones updater para evitar dependencias de estado
- Limpiar efectos que crean subscripciones

### Ejemplo Correcto

```tsx
// Cleanup de efecto
useEffect(() => {
  const controller = new AbortController();
  fetchData(controller.signal);
  return () => controller.abort();
}, [fetchData]);

// Funcion updater para evitar dependencia
const increment = useCallback(() => {
  setCount(c => c + 1);  // No necesita count en deps
}, []);
```

## Reglas de Estado

### Principios
- Minimo estado necesario
- Derivar valores cuando sea posible
- Estado en el ancestro comun mas bajo
- Inmutabilidad siempre

### Ejemplo Correcto

```tsx
// Derivar en lugar de sincronizar
const [items, setItems] = useState<Item[]>([]);
const total = useMemo(
  () => items.reduce((sum, i) => sum + i.price, 0),
  [items]
);

// Actualizacion inmutable
const addItem = (item: Item) => {
  setItems(prev => [...prev, item]);
};
```

### Ejemplo Incorrecto

```tsx
// Estado redundante
const [items, setItems] = useState([]);
const [total, setTotal] = useState(0);

useEffect(() => {
  setTotal(items.reduce(...));  // Sincronizando estado derivado
}, [items]);

// Mutacion directa
const addItem = (item) => {
  items.push(item);  // Mutando!
  setItems(items);
};
```

## Reglas de Performance

### Evitar
- Objetos/funciones inline en JSX (causan re-renders)
- Index como key en listas dinamicas
- Context con muchos valores que cambian frecuentemente

### Usar
- `React.memo` para componentes puros con props estables
- `useMemo` para calculos costosos
- `useCallback` para funciones pasadas a componentes memorizados
- Code splitting con `React.lazy` y `Suspense`

### Ejemplo Correcto

```tsx
// Extraer objetos estaticos
const STYLES = { color: 'red' };

// Memorizar componente
const MemoizedChild = React.memo(Child);

// Memorizar callback pasado a hijo memorizado
const handleClick = useCallback(() => {
  doSomething(id);
}, [id]);

<MemoizedChild onClick={handleClick} style={STYLES} />
```

## Reglas de TypeScript

### Requerido
- Tipos explicitos para props
- No usar `any` (preferir `unknown` o tipos especificos)
- Discriminated unions para props variantes

### Ejemplo Correcto

```tsx
// Discriminated union
type ButtonProps =
  | { variant: 'link'; href: string }
  | { variant: 'button'; onClick: () => void };

// Genericos para componentes reutilizables
interface ListProps<T> {
  items: T[];
  renderItem: (item: T) => ReactNode;
}

function List<T>({ items, renderItem }: ListProps<T>) {
  return <ul>{items.map(renderItem)}</ul>;
}
```

## Razon

Estas reglas:
- Previenen bugs comunes de React
- Mejoran la performance
- Mantienen el codigo predecible y testeable
- Aprovechan TypeScript para seguridad de tipos

## Cuando Romper las Reglas

- Prototipos rapidos (documentar deuda tecnica)
- Optimizacion prematura (medir antes de memorizar)
- Librerias que requieren patrones especificos
