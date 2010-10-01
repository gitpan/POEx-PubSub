package POEx::PubSub::Event;
BEGIN {
  $POEx::PubSub::Event::VERSION = '1.102740';
}

#ABSTRACT: An event abstraction for POEx::PubSub

use MooseX::Declare;

class POEx::PubSub::Event {
    use POEx::PubSub::Types(':all');
    use MooseX::Types::Moose(':all');


    has name =>
    (
        is          => 'rw',
        isa         => Str,
        required    => 1,
    );


    has subscribers =>
    (
        traits      => ['Hash'],
        is          => 'rw', 
        isa         => HashRef[Subscriber], 
        default     => sub { {} },
        lazy        => 1,
        clearer     => 'clear_subscribers',
        handles     => {
            all_subscribers => 'values',
            has_subscribers => 'count',
            add_subscriber => 'set',
            remove_subscriber => 'delete',
            get_subscriber => 'get',
        }
    );


    has publisher =>
    (
        is          => 'rw',
        isa         => Str,
        predicate   => 'has_publisher',
    );


    has publishtype =>
    (
        is          => 'rw',
        isa         => PublishType,
        default     => +PUBLISH_OUTPUT,
        trigger     => 
        sub { 
            my ($self, $type) = @_;
            confess 'Cannot set publishtype to INPUT if there is no publisher' 
                if $type == +PUBLISH_INPUT and not $self->has_publisher;
        }
    );


    has input =>
    (
        is          => 'rw',
        isa         => Str,
        predicate   => 'has_input',
        trigger     => 
        sub {
            my ($self) = @_;
            confess 'Cannot set input on Event if publishtype is OUTPUT'
                if $self->publishtype == +PUBLISH_OUTPUT;
            confess 'Cannot set inout if there is no publisher'
                if not $self->has_publisher;
        },
    );
}

1;



=pod

=head1 NAME

POEx::PubSub::Event - An event abstraction for POEx::PubSub

=head1 VERSION

version 1.102740

=head1 DESCRIPTION

POEx::PubSub::Event is a simple abstraction for published and 
subscribed events within PubSub. When using the find_event method or the
listing method from PubSub, you will receive this object.

=head1 PUBLIC_ATTRIBUTES

=head2 name

    is: rw, isa: Str, required: 1

The name of the event.

=head2 subscribers

    traits: Hash, is: rw, isa: HashRef[Subscriber]

subscribers holds all of the subscribers to this event. Subscribers can be accessed via the following methods:
 {
        all_subscribers => 'values',
        has_subscribers => 'count',
        add_subscriber => 'set',
        remove_subscriber => 'delete',
        get_subscriber => 'get',
    }

=head2 publisher

    is: rw, isa: Str

The event's publisher.

=head2 publishtype

    is: rw, isa => PublishType

The event's publish type. Defaults to +PUBLISH_OUTPUT.

=head2 input

    is: rw, isa: Str

If the publishtype is set to PUBLISH_INPUT, this will indicate the input
handling event that belongs to the publisher

=head1 AUTHOR

Nicholas Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Nicholas Perez.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

