type data
type action = SetData(string, data)

external toData: 'a => data = "%identity"
external fromData: data => 'a = "%identity"

let reducer = (state, action) =>
  switch action {
  | SetData(key, val) => {
      state->Dict.set(key, val)
      state
    }
  }

module StoreData = {
  type state = {state: dict<data>, update: action => unit}
}
module Store = Zustand.MakeStore(StoreData)

let store = Store.create(set => {
  state: Dict.make(),
  update: action => set(prev => {...prev, state: prev.state->reducer(action)}),
})

let use = _ => store->Store.use(state => state)
let useShallow = selector => store->Store.use(Store.useShallow(selector))
