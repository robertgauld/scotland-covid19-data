# Scotland's Covid-19 Data

A collection of charts visualising data around Covid-19 in Scotland, as displayed at [https://scotland-covid19-data.herokuapp.com/](https://scotland-covid19-data.herokuapp.com/). The data is pulled from two repositories:
- [watty62's Scot_covid19](https://github.com/watty62/Scot_covid19)
- [tomwhite's covid-19-uk-data](https://github.com/tomwhite/covid-19-uk-data)

If you want to try at home it should be as easy as installing gnuplot and the gems in the bundle.
It uses rack to present a webview, simply run 'bundle exec rackup' to start the server.
To get the data and generate the graphs run "bundle exec generate-site", to view them in your browser
run "bundle exec rackup" and goto the url it gives you.

A github action is used to generate the site after a push to master, at 7AM or at 7PM, the generated
files are then committed and pushed to the published-site branch. At which point heroku picks it up
and makes it available at scotland-covid19-data.herokuapp.com.

The files are organised as such:
- data/ - this is used to store the downloaded data
- public/ - the css and generated csv and plots live here
- template/index.html.haml - this is the template for generating the index
- console - start irb with this code already available
- middleware/ - stuff used by rack for logging and generating the index
- The other files are organised for the benefit of Zeitwerk's autoloading

The app is organised as such:
- UkCovid19Data - makes the UK data available to the rest of the app
- ScotlandCovid19Data - makes the Scotland data available to the rest of the app
- Make::Data - arranges the data from UkCovid19Data and ScotlandCovid19Data for the other Make classes
- Make::Csv - makes the csv files, saving them to the public dir
- Make::Plot - makes the plots, saving them to the public dir or using gnuplot to display on screen
- Make::Html - generates the index

Originally I loaded the csv data for Scotland and my local health board into libreoffice to make the plot for
my curiousity. Before finding out it could be done using gnuplot to read the csv and spit out a graph. I then
automated it for my pleasure before realising it would be simple to add a web front end.
If you look at the commit history you'll see this play out and the ugly throw away code slowly get more organised.
