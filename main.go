/* this stub code doesn't do anything except compile; it is only used for
* caching go module dependencies
 */
package main

import (
	"context"
	"encoding/base64"
	"fmt"
	"log"
	"os"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/encoding/protojson"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"

	"lambdastub.bopmatic.com/pb"
)

var conn *grpc.ClientConn
var client pb.StubsClient

func handler_StubRpc(ctx context.Context, request events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	var req pb.StubRpcRequest
	var resp *pb.StubRpcReply
	var err error

	decodedData, err := base64.StdEncoding.DecodeString(request.Body)
	if err != nil {
		return events.APIGatewayV2HTTPResponse{}, fmt.Errorf("Failed to decode req: %w", err)
	}
	err = protojson.Unmarshal(decodedData, &req)
	resp, err = client.StubRpc(ctx, &req)
	fmt.Printf("resp is %v", resp)
	return events.APIGatewayV2HTTPResponse{}, err
}

func main() {
	someVar := os.Getenv("SOMEVAR")
	log.Printf("someVar is %v\n", someVar)
	os.Exit(1)

	conn, _ := grpc.Dial("localhost:26001")
	client = pb.NewStubsClient(conn)

	lambda.Start(handler_StubRpc)
}
