// Configure the connection to AWS.
var AWS = require('aws-sdk');
AWS.config.region = 'us-west-2';


// Make a timestamp for the backups.
var now = new Date();
var year = now.getFullYear();
var month = now.getMonth() + 1;
month = (month < 10 ? "0" : "") + month;
var day = now.getDate();
day = (day < 10 ? "0" : "") + day;
var hour = now.getHours();
var min = now.getMinutes();
now = year + "-" + month + "-" + day +  "-" + hour + "-" + min;

// Function called by AWS Lambda.
exports.handler = function(event, context) {
    
    // Log basic call details to CloudWatch Logs.
    console.log("\nRequest received:\n", JSON.stringify(event));
    console.log("\nContext received:\n", JSON.stringify(context));

    // Log connection details to CloudWatch Logs.
    console.log("\nConnecting to EC2 service in region %s.",AWS.config.region);
    var ec2 = new AWS.EC2();
    console.log("\nConnected!");


    // Retrieve all volumes from current region.
    var params = {};
    console.log("\nRetrieving all EBS-backed volumes...");
    ec2.describeVolumes(params, function(err, data) {
        if (err) {
            console.log("\nCould not retrieve volumes. Error!");
            console.log(err, err.stack);
        } else {
            // Print out a count of volumes we need to account for.
            console.log('\nVolumes retrieved! Total volumes found: ',data.Volumes.length);
            
            // For each volume we need to get the Name tag for the snapshot description.
            // Then once we have that we need to make the snapshot call.
            for (i = 0; i < data.Volumes.length; ++i) {
                if (data.Volumes[i].State === "available") {
                    // Unattached volumes should be deleted (unless you want to waste
                    // money).
                    console.log("\nFound volume %s, but it is unattached and should be cleaned up.", data.Volumes[i].VolumeId);
                } else if (data.Volumes[i].State === "in-use") {
                    console.log("\nFound volume %s on instance %s.", data.Volumes[i].VolumeId, data.Volumes[i].Attachments[0].InstanceId);
                    // Lets get the instance's name.
                    var paramsTag = {
                        Filters: [
                            { Name: "resource-id", Values: [data.Volumes[i].Attachments[0].InstanceId, data.Volumes[i].VolumeId] },
                            { Name: "key", Values: ["Name"] }
                        ]
                    };
                    ec2.describeTags(paramsTag, function(err, data) {
                        if (err) console.log(err, err.stack);
                        else {
                            console.log("\nInstance identified as %s (%s).", data.Tags[0].Value, data.Tags[0].ResourceId);
                            
                            // Now that we have the name lets create the snapshot.
                            paramsSnap = {
                                VolumeId: paramsTag.Filters[0].Values[1],
                                Description: now + " - snapshot for " + data.Tags[0].Value,
                                DryRun: false
                            };
                            ec2.createSnapshot(paramsSnap, function(err, data) {
                                if (err) console.log(err, err.stack);
                                else {
                                    console.log(paramsSnap.Description);
                                }
                            });
                        }
                    });
                }
            }
            console.done();
        }
    });
};