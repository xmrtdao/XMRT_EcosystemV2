import { useState } from 'react'

function App() {
  const [count, setCount] = useState(0)
  return (
    <div className="App">
      <h1>🚀 XMRT Ecosystem V2</h1>
      <p>Decentralized Financial Freedom</p>
      <button onClick={() => setCount(count + 1)}>Count: {count}</button>
    </div>
  )
}

export default App