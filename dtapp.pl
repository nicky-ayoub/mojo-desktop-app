#!/usr/bin/env perl
use 5.014;
use strict;
use warnings;
use Carp;
use Browser::Open qw( open_browser );
#
# This effort is based on the following talk by 
# Build a desktop application with Perl, HTTP::Engine, SQLite and jQuery
# By Tatsuhiko Miyagawa (‎miyagawa‎):
# 
# http://www.yapcna.org/yn2009/talk/2018
#
# The database example comes from Joel Berger
# 
# http://blogs.perl.org/users/joel_berger/2012/10/a-simple-mojoliciousdbi-example.html
#
my $port = Mojo::IOLoop->generate_port;
my $url  = "http://127.0.0.1:$port";

my $me = $$;

my $pid = fork;

if ( !defined $pid ) {
    croak "Cannot fork: $!";
}
elsif ( $pid == 0 ) {

    # child process
    sleep 1;    # Just because...
    open_browser($url);
    say "Here we go...";
}
else {
    use Mojolicious::Lite;

    # connect to database
    use DBI;
    my $dbh = DBI->connect( "dbi:SQLite:database.db", "", "" )
      or die "Could not connect";

    # shortcut for use in template
    helper db => sub { $dbh };

    plugin 'Config';

    my $name = app->config('name');
    get '/' => sub {
        my $self = shift;
        $self->render('index');
    };

    get '/kill' => sub {
        my $self = shift;
        $self->res->code(301);
        $self->redirect_to('http://www.google.com');
        $self->app->log->debug("Goodbye, $name.");

        # I need this function to return so I delay the kill a little.
        system("(sleep 1; kill $me)&");
    };

    my $insert;
    while (1) {    # Repeat forever until disk space is available.

        # create insert statement
        $insert = eval { $dbh->prepare('INSERT INTO people VALUES (?,?)') };

        # break out of loop if statement prepared
        last if $insert;

       # if statement didn't prepare, assume its because the table doesn't exist
        warn "Creating table 'people'\n";
        $dbh->do('CREATE TABLE people (name varchar(255), age int);');
    }

    # setup route which receives data and returns to /
    post '/insert' => sub {
        my $self = shift;
        my $name = $self->param('name');
        my $age  = $self->param('age');
        $insert->execute( $name, $age );
        $self->redirect_to('/');
    };

    app->start( 'daemon', '-l', $url );
}

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
% my $sth = db->prepare('SELECT * FROM people');
% $sth->execute;
  <form action="<%=url_for('insert')->to_abs%>" method="post">
    Name: <input type="text" name="name"> Age: <input type="text" name="age"> <input type="submit" value="Add">
  </form>
  <br>
  Data: <br>
  <table border="1">
    <tr>
      <th>Name</th>
      <th>Age</th>
    </tr>
    % while (my $row = $sth->fetchrow_arrayref) {
      <tr>
        % for my $text (@$row) {
          <td><%= $text %></td>
        % }
      </tr>
    % }
  </table>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
        <title><%= config 'name' %></title>
    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css">
    <!-- Optional theme -->
    <link rel="stylesheet" href="//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap-theme.min.css">
    <!-- Latest compiled and minified JavaScript -->
    <script src="//netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"></script>

  </head>
  <body>
    <h1><%= config 'name' %></h1>
    <div class="well">This is a <%= config 'name' %> application.</div>
    <%= content %>

    <div><a class="btn btn-sm btn-danger" href="/kill">Quit</a></div>
    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script src="js/bootstrap.min.js"></script>
  </body>
</html>

