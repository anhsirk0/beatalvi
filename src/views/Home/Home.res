@react.component
let make = () => {
  <div className="size-full flex flex-col p-4 px-8 2xl:p-8 r-gap min-w-0 overflow-y-auto min-h-0">
    <HomeTopTracks />
    <HomeTopAlbums />
  </div>
}
