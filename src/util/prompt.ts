import enquirer from "enquirer";

export const prompt = enquirer.prompt as <T>(questions: unknown) => Promise<T>;
