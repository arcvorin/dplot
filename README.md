# DPlot

DPlot is a macOS graphic interface for [gnuplot](http://www.gnuplot.info/). It helps build and preview plot definitions through a document-based SwiftUI app while using gnuplot for the actual plotting engine.

The app was originally called DaniPlot, inspired by my lovely partner's name. It has since been renamed and shortened to DPlot. Some internal project names may still refer to DaniPlot while that transition is ongoing.

## Requirements

- macOS
- Xcode, if building from source
- gnuplot installed locally

DPlot does not bundle gnuplot. It expects a `gnuplot` executable to be available on your machine. The app checks common Homebrew locations first:

- `/opt/homebrew/bin/gnuplot` on Apple Silicon Macs
- `/usr/local/bin/gnuplot` on Intel Macs or older Homebrew installs

It also falls back to finding `gnuplot` on your shell `PATH`.

## Installing gnuplot with Homebrew

If you do not already have Homebrew installed, follow the instructions at [brew.sh](https://brew.sh/).

Then install gnuplot:

```sh
brew install gnuplot
```

You can verify the installation with:

```sh
gnuplot --version
```

## Downloading DPlot

You can find packaged builds on the [DPlot releases page](https://github.com/arcvorin/dplot/releases).

The current release is available here: [Latest Release](https://github.com/arcvorin/dplot/releases/latest).

## Building DPlot

Open `DPlot.xcodeproj` in Xcode, select the app scheme, and build/run the project.

## Beta Notice

DPlot is still in beta. The current `.dplot` document format version is `1`, and breaking changes may occur before the format stabilizes.

I recommend keeping track of which version of DPlot you used to create or edit important `.dplot` files. If a future beta changes the file format, knowing the version you used can make it easier to revert to that version and recover or migrate older documents.

## License

DPlot is licensed under terms aligned with the gnuplot license. See [LICENSE](LICENSE) for details.
