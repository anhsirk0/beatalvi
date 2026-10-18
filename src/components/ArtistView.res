@react.component
let make = (~artist: Shape.Artist.t) => {
  Console.log(artist)

  <div className="center">
    <div className="text-7xl"> {"ArtistView"->React.string} </div>
  </div>
}
