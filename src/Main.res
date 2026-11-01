%%raw("import './styles/index.css'")
%%raw("import 'lenis/dist/lenis.css'")

switch ReactDOM.querySelector("#beatalvi") {
| Some(root) =>
  ReactDOM.Client.createRoot(root)->ReactDOM.Client.Root.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>,
  )
| None => ()
}
