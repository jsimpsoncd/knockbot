# Challenge:response bot 
use strict;
use warnings;
use POE qw(Component::IRC);
use Data::Dumper;
my $nickname = 'knockbot';
my $ircname  = 'knockbot';
my $server   = 'irc.jesusrocksonirc.net';
my %challenge; 
my @channels = ('#knock');
# load challenges
open my $handle, '<', 'questions.txt';
chomp(my @array = <$handle>);
close $handle;
# We create a new PoCo-IRC object
my $irc = POE::Component::IRC->spawn(
   nick => $nickname,
   ircname => $ircname,
   server  => $server,
) or die "Oh noooo! $!";
 
POE::Session->create(
    package_states => [
        main => [ qw(_default _start irc_001 irc_public irc_msg) ],
    ],
    heap => { irc => $irc },
);
 
$poe_kernel->run();
 
sub _start {
    my $heap = $_[HEAP];

    # retrieve our component's object from the heap where we stashed it
    my $irc = $heap->{irc};

    $irc->yield( register => 'all' );
    $irc->yield( connect => { } );
    return;
}
 
sub irc_001 {
    my $sender = $_[SENDER];

    # Since this is an irc_* event, we can get the component's object by
    # accessing the heap of the sender. Then we register and connect to the
    # specified server.
    my $irc = $sender->get_heap();

    print "Connected to ", $irc->server_name(), "\n";

    # we join our channels
    $irc->yield( join => $_ ) for @channels;
    return;
}
 
sub irc_msg {
    my ($sender, $who, $where, $what) = @_[SENDER, ARG0 .. ARG2];
    my $nick = ( split /!/, $who )[0];
    if ( my ($knock) = $what =~ /^knock (.+)/ ) {
    print "Generate a challenge $nick\n";
    my @randline = split(":", $array[rand @array]);
    my $key = $randline[0];
    my $value = $randline[1];
    if ($knock eq "knock") {
        $irc->yield ( privmsg => $nick => $key );
        print "The Secret response for $nick is $value\n";
        $challenge{'$nick'} = $value;
    }
    }
    print $challenge{'$nick'}."\n";
    if (exists($challenge{'$nick'})) {
        if ( lc($what) eq $challenge{'$nick'}) {
            $irc->yield ( privmsg => $nick => "Correct response. Invite issued. Have a nice day." );
            print "CORRECT!\n";
        }
    }
    return;
}

sub irc_public {
    my ($sender, $who, $where, $what) = @_[SENDER, ARG0 .. ARG2];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];

    if ( my ($rot13) = $what =~ /^rot13 (.+)/ ) {
        $rot13 =~ tr[a-zA-Z][n-za-mN-ZA-M];
        $irc->yield( privmsg => $channel => "$nick: $rot13" );
    }
    return;
}

# We registered for all events, this will produce some debug info.
sub _default {
    my ($event, $args) = @_[ARG0 .. $#_];
    my @output = ( "$event: " );

    for my $arg (@$args) {
        if ( ref $arg eq 'ARRAY' ) {
            push( @output, '[' . join(', ', @$arg ) . ']' );
        }
        else {
            push ( @output, "'$arg'" );
        }
    }
    print join ' ', @output, "\n";
    return;
}

