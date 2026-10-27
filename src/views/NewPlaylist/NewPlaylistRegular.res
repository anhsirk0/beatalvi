let countLabel = (matching, total) =>
  `${matching->Int.toString} matching ${Constant.sep} ${total->Int.toString} songs`

module Content = {
  @react.component
  let make = (~tracks: array<Shape.Track.t>, ~data: option<Shape.Playlist.t>=?) => {
    let (query, setQuery) = React.useState(_ => "")
    let (selected, setSelected) = React.useState(_ =>
      switch data {
      | Some(data) => tracks->Array.filter(t => data.tracks->Array.includes(t.uri))
      | None => []
      }
    )

    let onChange = evt => {
      evt->ReactEvent.Form.stopPropagation
      setQuery(_ => evt->Util.Dom.targetValue)
    }

    let filteredTracks = React.useMemo2(() => {
      tracks->Array.filter(Shape.Track.filterQuery(_, query))
    }, (query, tracks))

    let filteredSelected = React.useMemo2(() => {
      selected->Array.filter(Shape.Track.filterQuery(_, query))
    }, (query, selected))

    let onToggle = track => setSelected(tracks => tracks->Util.Arr.toggle(track))
    let toggleAll = add =>
      setSelected(_ =>
        filteredTracks->Array.reduce(selected, add ? Shape.Track.addOne : Shape.Track.removeOne)
      )

    let onSubmit = name => {
      if name->String.length < 1 {
        Toast.error("Please enter a name to create a playlist.")
      } else if selected->Array.length < 1 {
        Toast.error("Please select atleast one song to be added in the playlist.")
      } else {
        let uris = selected->Array.map(t => t.uri)
        switch data {
        | Some(data) =>
          if uris == data.tracks && data.playlist.name == name {
            Toast.info("No changes were made")
          } else {
            Invoke.updatePlaylist({id: data.playlist.id, name, uris})
            ->Promise.catch(async _e => -1.)
            ->Promise.then(async id => {
              id > 0.
                ? Toast.success("Playlist updated.")
                : Toast.error("Failed to update playlist.")
            })
            ->ignore
          }
        | None =>
          Invoke.createPlaylist({name, uris})
          ->Promise.catch(async _e => -1.)
          ->Promise.then(async id => {
            id > 0. ? Toast.success("Playlist created.") : Toast.error("Failed to create playlist.")
          })
          ->ignore
        }
        RescriptReactRouter.replace(Route.toPath(Playlists))
      }
    }

    <React.Fragment>
      <Portal id="tools">
        <div className="p-4 flex flex-col gap-4 bg-base-100 nb-outline rounded-box">
          <p className="r-text-sm uppercase text-80 -mb-1">
            {"Filter songs by song/album/artist name"->React.string}
          </p>
          <label
            className="input input-xl outline-none bg-base-200 nb-box active:nb-active has-focus:nb-active w-full mb-4"
          >
            <Icon.magnifyingGlass className="r-icon" />
            <InputBase
              id="search-input"
              value=query
              onChange
              type_="text"
              className="grow"
              placeholder=" Search songs"
            />
          </label>
          <p className="r-text-sm uppercase text-80 -mb-1">
            {"Select or deselect matching songs"->React.string}
          </p>
          <div className="w-full join isolate">
            <button
              onClick={_ => toggleAll(true)} className="join-item btn xl:btn-lg 2xl:btn-xl flex-1"
            >
              {"Select all"->React.string}
            </button>
            <button
              onClick={_ => toggleAll(false)}
              className="join-item btn xl:btn-lg 2xl:btn-xl flex-1 z-10"
            >
              {"Deselect all"->React.string}
            </button>
          </div>
        </div>
        <div className="grow"></div>
        <NewPlaylistSubmitBtn onSubmit name=?{data->Option.map(d => d.playlist.name)} />
      </Portal>
      <ItemsContainer
        title="In this playlist"
        subtitle={countLabel(filteredSelected->Array.length, selected->Array.length)}
        classes="col-span-14 lg:col-span-7 xl:col-span-5 min-h-[65vh]"
      >
        {filteredSelected->Array.length > 0
          ? <Virtuoso
              id="selected-tracks"
              style={{display: "flex", flexDirection: "column"}}
              data=filteredSelected
              itemContent={(idx, track) =>
                <PlaylistsTrackItem
                  key={track.id->Float.toString}
                  track
                  index={idx + 1}
                  isSelected={selected->Array.some(Shape.Track.eq(track, _))}
                  onToggle
                  forSelected=true
                />}
            />
          : <div className="center size-full">
              <p className="r-text-2xl font-instrument font-light italic text-center">
                {"Selected songs will gather here."->React.string}
              </p>
            </div>}
      </ItemsContainer>
      <ItemsContainer
        title="All Songs"
        subtitle={countLabel(filteredTracks->Array.length, tracks->Array.length)}
        classes="col-span-14 lg:col-span-7 xl:col-span-5 min-h-[65vh]"
      >
        <Virtuoso
          id="tracks"
          style={{display: "flex", flexDirection: "column"}}
          data=filteredTracks
          itemContent={(idx, track) =>
            <PlaylistsTrackItem
              key={track.id->Float.toString}
              track
              index={idx + 1}
              isSelected={selected->Array.some(Shape.Track.eq(track, _))}
              onToggle
            />}
        />
      </ItemsContainer>
    </React.Fragment>
  }
}

@react.component
let make = (~data=?) => {
  let tracks = Hook.useFetch({fn: Invoke.getAllTracksGroupedByAlbum})

  switch tracks {
  | Loading | Failed => React.null
  | Success(tracks) => <Content tracks ?data />
  }
}
