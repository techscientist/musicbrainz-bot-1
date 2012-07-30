#!/usr/bin/perl

package MusicBrainzBot;
use utf8;
use WWW::Mechanize;

sub new {
	my ($package, $args) = @_;
	my %hash;
	%hash = (
		'server' => $args->{server} || 'musicbrainz.org',
		'username' => $args->{username},
		'password' => $args->{password},
		'useragent' => 'MusicBrainz bot/0.1',
		'verbose' => $args->{verbose},
		'mech' => WWW::Mechanize->new(agent => $self->{'useragent'}, autocheck => 1),
	);
	bless \%hash => $package;
}

sub login {
	my ($self) = @_;
	my $mech = $self->{'mech'};

	if (!$self->{'username'}) {
		print "Username: ";
		$self->{'username'} = <>;
		chomp($self->{'username'});
		print "\n";
	}

	if (!$self->{'password'}) {
		system "stty -echo";
		print "Password for ".$self->{'username'}.": ";
		$self->{'password'} = <>;
		system "stty echo";
		print "\n";
	}

	# load login page
	my $url = "http://".$self->{'server'}."/login";
	print "Logging in as ".$self->{'username'}." at $url.\n" if $self->{'verbose'};
	$mech->get($url);
	sleep 1;

	# submit login page
	my $r = $mech->submit_form(
		form_number => 2,
		fields => {
			username => $self->{'username'},
			password => $self->{'password'},
		}
	);
	sleep 1;

	# TODO: Check that login worked

	$self->{'loggedin'} = 1;
}

sub edit_artist {
	my ($self, $mbid, $opt) = @_;

	return $self->edit_entity("artist", $mbid, $opt);
}

sub edit_release_group {
	my ($self, $mbid, $opt) = @_;

	return $self->edit_entity("release-group", $mbid, $opt);
}

# the release editor differs from the other forms
#sub edit_release {
#}

sub edit_recording {
	my ($self, $mbid, $opt) = @_;

	return $self->edit_entity("recording", $mbid, $opt);
}

sub edit_work {
	my ($self, $mbid, $opt) = @_;

	return $self->edit_entity("work", $mbid, $opt);
}

sub edit_label {
	my ($self, $mbid, $opt) = @_;

	return $self->edit_entity("label", $mbid, $opt);
}

sub edit_url {
	my ($self, $mbid, $opt) = @_;

	return $self->edit_entity("url", $mbid, $opt);
}

sub edit_entity {
	my ($self, $entity, $mbid, $opt) = @_;
	my $mech = $self->{'mech'};

	die "No MBID provided" unless $mbid;

	$self->login() if !$self->{'loggedin'};

	my $url = "http://".$self->{'server'}."/$entity/$mbid/edit";
	print "$url\n";
	$mech->get($url);

	$mech->form_number(2);
	$mech->field("edit-$entity.as_auto_editor", 0); # TODO: This will presumably fail if the field is not there
	for my $k (keys %$opt) {
		$mech->field("edit-$entity.$k", $opt->{$k});
	}
	my $r = $mech->submit();
	sleep 1;

	# TODO: Check that submitting worked.

	return 1;
}

1;