package Cpanel::CloudFlare::Zone;

use Cpanel::CloudFlare::Api;
use Cpanel::CloudFlare::UserStore;

use Cpanel::CloudFlare::Logger();

use strict;

my $logger = Cpanel::CloudFlare::Logger->new();
my $cf_user_store = Cpanel::CloudFlare::UserStore->new("home_dir", $Cpanel::homedir , "user" , $Cpanel::CPDATA{'USER'});
{
    # Store the loaded user
    my $zones = {};

    sub load {
        my $zone_name = shift;

        my $page = 1;
        my $per_page = 50;
        my $total_count = 0;

        while (!defined $zones->{$zone_name} && (($page-1) * $per_page) <= $total_count) {
            my $api_response = Cpanel::CloudFlare::Api::client_api_request_v4('GET', "/zones/", {
                "name" => $zone_name,
                "per_page" => $per_page,
                "page" => $page
            });

            my $results = $api_response->{"result"};

            foreach my $zone (@{$results}) {
                $zones->{$zone->{"name"}} = $zone;
            }

            $total_count = $api_response->{"result_info"}->{"total_count"};
            $page++;
        }

        if (!defined $zones->{$zone_name}) {
            return 0;
        }

        return 1;
    }

    sub get_zone_tag {
        my $zone_name = shift;
        my $zone_tag;

        # Load the YAML file
        my $cf_global_data = $cf_user_store->__load_data_file();

        # Are there any zone tags in the YAML file?
        if((defined $cf_global_data->{$cf_user_store->CF_ZONE_TAGS_KEY}) && (defined $cf_global_data->{$cf_user_store->CF_ZONE_TAGS_KEY}->{$zone_name})) {
            # Is our zone tag cached?
            if(defined $cf_global_data->{$cf_user_store->CF_ZONE_TAGS_KEY}->{$zone_name}) {
                $logger->info("Zone tag for '". $zone_name ."' was found in the YAML cache.");
                $zone_tag = $cf_global_data->{$cf_user_store->CF_ZONE_TAGS_KEY}->{$zone_name};
            } else {

            }
        } else {
            if(!defined $cf_global_data->{$cf_user_store->CF_ZONE_TAGS_KEY}) {
                $cf_global_data->{$cf_user_store->CF_ZONE_TAGS_KEY} = {};
            }

            # Make an API call to get the zone tag
            if (!defined $zones->{$zone_name} && !load($zone_name)) {
                   $logger->warn("Unable to load zone '". $zone_name ."'.  Domain may not be currently associated with this account.\n");
            } else {
                $zone_tag = $zones->{$zone_name}->{"id"};
                $logger->info("Zone tag for '". $zone_name ."' was NOT in the YAML cache.");
            }
            # save the zone tag to the yaml file
            $cf_global_data->{$cf_user_store->CF_ZONE_TAGS_KEY}->{$zone_name} = $zone_tag;
            $cf_user_store->__save_data_file($cf_global_data);
        }

        return $zone_tag;
    }
}

1;
