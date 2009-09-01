package POEx::PubSub::Event;
our $VERSION = '0.092440';


#ABSTRACT: An event abstraction for POEx::PubSub

use MooseX::Declare;

class POEx::PubSub::Event
{
    use MooseX::AttributeHelpers;
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
        metaclass   => 'Collection::Hash',
        is          => 'rw', 
        isa         => HashRef[Subscriber], 
        default     => sub { {} },
        lazy        => 1,
        clearer     => 'clear_subscribers',
        provides    =>
        {
            values  => 'all_subscribers',
            count   => 'has_subscribers',
            set     => 'add_subscriber',
            delete  => 'remove_subscriber',
            get     => 'get_subscriber',
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
        sub
        { 
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
        sub
        {
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

version 0.092440

=head1 DESCRIPTION

POEx::PubSub::Event is a simple abstraction for published and 
subscribed events within PubSub. When using the find_event method or the
listing method from PubSub, you will receive this object.

=head1 ATTRIBUTES

=head2 name

The name of the event.



=head2 subscribers, predicate => 'has_subscribers', clearer => 'clear_subscribers

The event's subscribers stored in a Set::Object



=head2 publisher, predicate => 'has_publisher'

The event's publisher.



=head2 publishtype, isa => PublishType

The event's publish type. 



=head2 input, predicate => 'has_input'

If the publishtype is set to PUBLISH_INPUT, this will indicate the input
handling event that belongs to the publisher



=head1 METHODS

=head2 all_subscribers()

This method is delegated to the subscribers attribute to return all of the
subscribers for this event



=head2 add_subscriber(Subscriber $sub)

Add the supplied subscriber to the event



=head2 remove_subscriber(Subscriber $sub)

Remove the supplied subscriber from the event



=head1 AUTHOR

  Nicholas Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Nicholas Perez.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut 



__END__

