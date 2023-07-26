# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# Copyright (C) 2023 mo-azfar, https://github.com/mo-azfar/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::PostMaster::Filter::PhoneNumberRecognition;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
	'Kernel::System::CustomerUser',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{ParserObject} = $Param{ParserObject} || die "Got no ParserObject";

    # Get communication log object and MessageID.
    $Self->{CommunicationLogObject} = $Param{CommunicationLogObject} || die "Got no CommunicationLogObject!";

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

	for my $Needed (qw(JobConfig GetParam)) {
        if ( !$Param{$Needed} ) {
            $Self->{CommunicationLogObject}->ObjectLog(
                ObjectLogType => 'Message',
                Priority      => 'Error',
                Key           => 'Kernel::System::PostMaster::Filter::PhoneNumberRecognition',
                Value         => "Need $Needed!",
            );
            return;
        }
    }

    # check if sender is of interest
    return 1 if !$Param{GetParam}->{From};

    if ( defined $Param{JobConfig}->{FromAddressRegExp} && $Param{JobConfig}->{FromAddressRegExp} )
    {

        if ( $Param{GetParam}->{From} !~ /$Param{JobConfig}->{FromAddressRegExp}/i ) {
            return 1;
        }
    }

    my $NumberRegExp = $Param{JobConfig}->{NumberRegExp};

    # search in the body
    if ( $Param{JobConfig}->{SearchInBody} ) {

        # split the body into separate lines
        my @BodyLines = split /\n/, $Param{GetParam}->{Body};

        # traverse lines and return first match
        LINE:
        for my $Line (@BodyLines) {
            if ( $Line =~ m{$NumberRegExp}ms ) {

                # get the found element value
                $Self->{Number} = $1;
                last LINE;
            }
        }
    }

    # we need to have found an phone number to proceed.
    if ( !$Self->{Number} ) {
        $Self->{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Message',
            Priority      => 'Debug',
            Key           => 'Kernel::System::PostMaster::Filter::PhoneNumberRecognition',
            Value         => "Could not find caller phone number => Ignoring",
        );
        return 1;
    }
    else {
        $Self->{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Message',
            Priority      => 'Debug',
            Key           => 'Kernel::System::PostMaster::Filter::PhoneNumberRecognition',
            Value         => "Found phone number $Self->{Number}",
        );
    }

	my $CustomerUserObject =  $Kernel::OM->Get('Kernel::System::CustomerUser');
	
	#search customer data based on phone number
	my $CustomerUserIDsRef = $CustomerUserObject->CustomerSearchDetail(
        UserMobile              => $Self->{Number}, 
        #DynamicField_FieldNameX => {
        #    Equals            => 123,
        #    Like              => 'value*',                # "equals" operator with wildcard support
        #    GreaterThan       => '2001-01-01 01:01:01',
        #    GreaterThanEquals => '2001-01-01 01:01:01',
        #    SmallerThan       => '2002-02-02 02:02:02',
        #    SmallerThanEquals => '2002-02-02 02:02:02',
        #},
        Result => 'ARRAY',
        Limit => 1,
    );
	
	if (!@{$CustomerUserIDsRef})
	{
		$Self->{CommunicationLogObject}->ObjectLog(
			ObjectLogType => 'Message',
			Priority      => 'Debug',
			Key           => 'Kernel::System::PostMaster::Filter::PhoneNumberRecognition',
			Value         => "Customer user not found by $Self->{Number}",
		);
	}
	else
	{
		foreach my $CustomerUserID (@{$CustomerUserIDsRef})
		{	
			$Self->{CommunicationLogObject}->ObjectLog(
				ObjectLogType => 'Message',
				Priority      => 'Debug',
				Key           => 'Kernel::System::PostMaster::Filter::PhoneNumberRecognition',
				Value         => "Found customer user $CustomerUserID by $Self->{Number}",
			);
			
			# get customer user data
			my %CustomerData = $CustomerUserObject->CustomerUserDataGet(
				User => $CustomerUserID,
			);
			
			$Param{GetParam}->{'X-OTRS-CustomerUser'}  = $CustomerUserID;
			
			if (%CustomerData) {
				$Param{GetParam}->{'X-OTRS-CustomerNo'}  = $CustomerData{UserCustomerID};;
			}
		}
	}
	
	return 1;

}

1;