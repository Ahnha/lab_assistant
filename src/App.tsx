import React from "react";
import { Page, PageHeader, PageHeaderTitle, Card, CardContent, Button } from "@skin-studio/react";

function App() {
  return (
    <Page>
      <PageHeader>
        <PageHeaderTitle>Lab Assistant</PageHeaderTitle>
      </PageHeader>
      <Card>
        <CardContent>
          <p>Welcome to Lab Assistant</p>
          <Button>Get Started</Button>
        </CardContent>
      </Card>
    </Page>
  );
}

export default App;
