# Capstone Reflection

## 1. What was the most challenging part of this project, and how did you overcome it?
The most challenging aspect was conceptualizing and implementing strict environment isolation. Initially, my staging and production Kubernetes manifests were identical. Through peer review, I realized production requires explicit resource requests/limits and higher replica counts to prevent node starvation and ensure high availability. I overcame this by researching Kubernetes best practices and updating `prod-deployment.yaml` accordingly.

## 2. How did you ensure your project meets the "new engineer onboarding in one day" standard?
I focused heavily on documentation and developer experience (DX). I structured the repository logically, provided a comprehensive README with step-by-step local setup instructions, and included executable, well-commented scripts like `smoke-test.sh`. By removing ambiguity about how to build, test, and deploy, I minimized the cognitive load for a new team member.

## 3. How did you use AI tools in this project, and how did you ensure academic integrity?
I used AI to generate boilerplate code, such as the initial Mermaid.js architecture diagram and the basic structure of the GitHub Actions workflow. However, I did not blindly copy-paste. I manually reviewed every line, adapted it to the specific KijaniKiosk context (e.g., adding the manual approval gate and namespace isolation), and tested it locally. All AI usage is transparently documented in the Scope Document.
