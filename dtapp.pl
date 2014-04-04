#!/usr/bin/env perl
use 5.014;
use strict;
use warnings;
use Carp;
use Browser::Open qw( open_browser );
#
# This effort is based on the flowwing talk by 
# Build a desktop application with Perl, HTTP::Engine, SQLite and jQuery
# By Tatsuhiko Miyagawa (‎miyagawa‎):
# http://www.yapcna.org/yn2009/talk/2018
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

    plugin 'Config';

    my $name = app->config('name');
    get '/' => sub {
        my $self = shift;
        $self->render('index');
    };
    get '/kill' => sub {
        my $self = shift;
        $self->app->log->debug("Goodbye, $name.");
        kill 'QUIT', $me;
    };

    app->start( 'daemon', '-l', $url );
}

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';

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
    <div><a class="btn btn-sm btn-danger" href="/kill">Quit</a></div>
    <%= content %>

    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script src="js/bootstrap.min.js"></script>
  </body>
</html>

